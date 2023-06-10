FROM alpine:3.15 as default

ARG BIN_NAME
# NAME and VAULT_VERSION are the name of the software in releases.hashicorp.com
# and the version to download. Example: NAME=vault VAULT_VERSION=1.2.3.
ARG NAME=vault
ARG VAULT_VERSION
ARG VAULT_REVISION
# TARGETARCH and TARGETOS are set automatically when --platform is provided.
ARG TARGETOS TARGETARCH

# Additional metadata labels used by container registries, platforms
# and certification scanners.
LABEL name="Vault" \
      maintainer="Vault Team <vault@hashicorp.com>" \
      vendor="HashiCorp" \
      version=${VAULT_VERSION} \
      release=${VAULT_REVISION} \
      revision=${VAULT_REVISION} \
      summary="Vault is a tool for securely accessing secrets." \
      description="Vault is a tool for securely accessing secrets. A secret is anything that you want to tightly control access to, such as API keys, passwords, certificates, and more. Vault provides a unified interface to any secret, while providing tight access control and recording a detailed audit log."

# Set ARGs as ENV so that they can be used in ENTRYPOINT/CMD
ENV NAME=$NAME
ENV VERSION=$VERSION
ENV CONTAINERPILOT_VER 3.8.5
ENV CONTAINERPILOT /etc/containerpilot.json5
ENV CONTAINERPILOT_REPO greenbaum

# Create a non-root user to run the software.
RUN addgroup ${NAME} && adduser -S -G ${NAME} ${NAME}

RUN apk update && \
    apk add --no-cache libcap su-exec curl tzdata

# Do Containerpilot stuff
RUN export CONTAINERPILOT_CHECKSUM=a515198e11b0f20f279f3663cebf16a9261219031e40c5047d5bb2bc09df3f21 \
    && curl -Lso /tmp/containerpilot.tar.gz \
         "https://github.com/${CONTAINERPILOT_REPO}/containerpilot/releases/download/${CONTAINERPILOT_VER}/containerpilot-${CONTAINERPILOT_VER}.tar.gz" \
    && echo "${CONTAINERPILOT_CHECKSUM}  /tmp/containerpilot.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerpilot.tar.gz -C /bin \
    && rm /tmp/containerpilot.tar.gz

# Get the ContainerPilot configuration
COPY containerpilot.json5 /etc/containerpilot.json5
ENV CONTAINERPILOT=/etc/containerpilot.json5


# Do Vault stuff
COPY dist/$TARGETOS/$TARGETARCH/$BIN_NAME /bin/

# /vault/logs is made available to use as a location to store audit logs, if
# desired; /vault/file is made available to use as a location with the file
# storage backend, if desired; the server will be started with /vault/config as
# the configuration directory so you can add additional config files in that
# location.
RUN mkdir -p /vault/logs && \
    mkdir -p /vault/file && \
    mkdir -p /vault/config && \
    chown -R ${NAME}:${NAME} /vault

# Expose the logs directory as a volume since there's potentially long-running
# state in there
VOLUME /vault/logs

# Expose the file directory as a volume since there's potentially long-running
# state in there
VOLUME /vault/file

# 8200/tcp is the primary interface that applications use to interact with
# Vault.
EXPOSE 8200

# The entry point script uses dumb-init as the top-level process to reap any
# zombie processes created by Vault sub-processes.
#
# For production derivatives of this container, you shoud add the IPC_LOCK
# capability so that Vault can mlock memory.
COPY .release/docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]


# Run Containerpilot which will run Vault for us.
CMD ["/bin/containerpilot"]
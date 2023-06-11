FROM ffmdekkers/base:v0.1.1
ARG IMGVERSION
ARG DEBIAN_FRONTEND=noninteractive

LABEL org.label-schema.name="Vault" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.description="Hashicorp Vault" \
    org.label-schema.vendor="Aer Lingus" \
    org.label-schema.url="https://github.com/MartijnDekkers-EI/docker-vault/blob/main/README.md" \
    org.label-schema.vcs-url="https://github.com/MartijnDekkers-EI/docker-vault" \
    org.label-schema.version=${IMGVERSION}

# /vault/logs is made available to use as a location to store audit logs, if desired;
# /vault/file is made available to use as a location with the file storage backend, if desired;
RUN mkdir -p /vault/logs \
    && mkdir -p /vault/file \
    && mkdir -p /etc/vault.d
    # chown -R ${NAME}:${NAME} /vault

# Expose the logs directory as a volume since there's potentially long-running
# state in there
VOLUME /vault/logs

# Expose the file directory as a volume since there's potentially long-running
# state in there
VOLUME /vault/file

# Expose Vault ports
EXPOSE 8200/tcp
EXPOSE 8201/tcp

COPY containerpilot.json5 /etc/containerpilot.json5
COPY init.sh /init.sh

ENTRYPOINT ["/bin/dumb-init", "--"]
CMD ["/bin/bash", "-c", "exec /init.sh"]
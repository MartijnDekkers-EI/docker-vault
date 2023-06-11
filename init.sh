#!/usr/bin/env bash

# Get the ContainerPilot configuration
# /usr/local/bin/consul kv get ${SCRIPT_SRC_PATH}/containerpilot.json5 > ${SCRIPTS_DIR}/containerpilot.json5

# run ContainerPilot
exec /bin/containerpilot -config /etc/containerpilot.json5
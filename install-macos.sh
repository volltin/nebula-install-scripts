#!/bin/bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Error: Nothing to do. Run again as root."
    exit
fi

echo -n "Enter node name: "
read ND_NAME

if [ -z "$ND_NAME" ]; then
    echo "Node name is empty"
    exit 2
fi

# define file paths
## binary
BINARY_FILE="macos/nebula"
## config
CONF_FILE="config/config-$ND_NAME.yml"
FALLBACK_CONF_FILE="config/config.yml"
## certs
CA_DIR="ca"
CA_FILE=$CA_DIR"/ca.crt"
CRT_FILE=$CA_DIR"/${ND_NAME}.crt"
KEY_FILE=$CA_DIR"/${ND_NAME}.key"

## check files
if [ ! -f "$BINARY_FILE" ]; then
    echo "Binary file '$BINARY_FILE' is missing."
    echo "Try: wget https://github.com/slackhq/nebula/releases/download/v1.0.0/nebula-darwin-amd64.tar.gz"
    exit 2
fi

if [ ! -f "$CA_FILE" ]; then
    echo "CA cert file is not found"
    exit 2
fi

if [ ! -f "$CRT_FILE" ]; then
    echo "Host crt file is not found"
    exit 2
fi

if [ ! -f "$KEY_FILE" ]; then
    echo "Host key file is not found"
    exit 2
fi

if [ ! -f "$CONF_FILE" ]; then
    echo "Host specific configuration file '$CONF_FILE' is not found, use '$FALLBACK_CONF_FILE' insdead."
    CONF_FILE=FALLBACK_CONF_FILE
fi

## make directory and copy config file
cp ${BINARY_FILE} "/usr/local/bin/nebula"

CONF_DIR="/etc/nebula"
mkdir -p   ${CONF_DIR}
cp ${CONF_FILE} ${CONF_DIR}/config.yml
cp ${CA_FILE}   ${CONF_DIR}/ca.crt
cp ${CRT_FILE}  ${CONF_DIR}/host.crt
cp ${KEY_FILE}  ${CONF_DIR}/host.key

cat <<EOF >/Library/LaunchDaemons/net.8d6c.nebula.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>KeepAlive</key>
    <true/>
    <key>Label</key>
    <string>net.8d6c.nebula</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/nebula</string>
        <string>-config</string>
        <string>/etc/nebula/config.yml</string>
    </array>
    <key>StandardErrorPath</key>
    <string>/tmp/net.8d6c.nebula.err</string>
    <key>StandardOutPath</key>
    <string>/tmp/net.8d6c.nebula.out</string>
</dict>
</plist>
EOF

launchctl unload net.8d6c.nebula.plist
launchctl load net.8d6c.nebula.plist

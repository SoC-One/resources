#!/bin/bash
KASM_VERSION=1.3.1

# Detecting the Linux distribution
if [ -x "$(command -v lsb_release)" ]; then
    DISTRO=$(lsb_release -i -s)
    case "$DISTRO" in
        Ubuntu)
            UBUNTU_VERSION=$(lsb_release -c -s)
            mkdir -p /tmp/kasm-cache
            cd /tmp/kasm-cache
            sudo apt install -y wget
            wget https://github.com/kasmtech/KasmVNC/releases/download/v${KASM_VERSION}/kasmvncserver_${UBUNTU_VERSION}_${KASM_VERSION}_amd64.deb
            sudo apt-get install ./kasmvncserver_*.deb
            sudo apt install -y ubuntu-mate-desktop
            sudo addgroup $USER ssl-cert
            ;;
        CentOS)
            mkdir -p /tmp/kasm-cache
            cd /tmp/kasm-cache
            sudo yum install -y perl-DateTime perl-DateTime-TimeZone wget
            wget https://github.com/kasmtech/KasmVNC/releases/download/v${KASM_VERSION}/kasmvncserver_centos_core_${KASM_VERSION}_x86_64.rpm
            sudo yum localinstall -y kasmvncserver_centos_core_${KASM_VERSION}_x86_64.rpm
            sudo yum groupinstall -y "MATE Desktop"
            sudo usermod -aG ssl-cert $USER
            newgrp ssl-cert
            ;;
        *)
            echo "Unsupported distribution: $DISTRO"
            exit 1
            ;;
    esac
else
    echo "lsb_release command not found. Cannot determine distribution."
    exit 1
fi

# Configuring VNC server
vncserver -kill :1   # Kill any existing VNC server on display :1 (if exists)

# Writing VNC server configuration to file
cat > ~/.vnc/kasmvnc.yaml << EOL
network:
  protocol: http
  ssl:
    require_ssl: false
  udp:
    public_ip: 127.0.0.1
EOL


# Setting up systemd service for VNC server
cat > vncserver@:1.service << EOL
[Unit]
Description=Remote desktop service (VNC)
After=syslog.target network.target

[Service]
Type=forking
User=administrator
ExecStartPre=/bin/sh -c '/usr/bin/vncserver -kill %i > /dev/null 2>&1 || :'
ExecStart=/usr/bin/vncserver -disableBasicAuth %i
ExecStop=/usr/bin/vncserver -kill %i

[Install]
WantedBy=default.target
EOL
sudo mv vncserver@:1.service /etc/systemd/system/vncserver@:1.service
sudo systemctl daemon-reload
sudo systemctl restart vncserver@:1.service
sudo systemctl  enable vncserver@:1.service
sudo systemctl status vncserver@:1.service
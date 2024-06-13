#!/bin/bash
KASM_VERSION=1.3.1
UBUNTU_VERSION=$(lsb_release -c | awk '{print $2}')
mkdir -p /tmp/kasm-cache
cd /tmp/kasm-cache
wget https://github.com/kasmtech/KasmVNC/releases/download/v${KASM_VERSION}/kasmvncserver_${UBUNTU_VERSION}_${KASM_VERSION}_amd64.deb
sudo apt-get install ./kasmvncserver_*.deb
sudo apt install -y ubuntu-mate-desktop
sudo addgroup $USER ssl-cert
vncserver -select-de mate

cat > ~/.vnc/kasmvnc.yaml << EOL
network:
  protocol: http
  ssl:
    require_ssl: false
  udp:
    public_ip: 127.0.0.1
EOL

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
#!/bin/bash
KASM_VERSION=1.3.1
USER=administrator
KASM_VNC_PASSWD=pAssword@11
# Detecting the Linux distribution
if [ -x "$(command -v lsb_release)" ]; then
    DISTRO=$(lsb_release -i -s)
    case "$DISTRO" in
        Ubuntu)
            UBUNTU_VERSION=$(lsb_release -c -s)
            mkdir -p /tmp/kasm-cache
            cd /tmp/kasm-cache
            sudo apt install -y wget expect
            wget https://github.com/kasmtech/KasmVNC/releases/download/v${KASM_VERSION}/kasmvncserver_${UBUNTU_VERSION}_${KASM_VERSION}_amd64.deb
            sudo apt-get install ./kasmvncserver_*.deb
            sudo apt install -y ubuntu-mate-desktop
            sudo addgroup $USER ssl-cert


            ;;
        CentOS)
            mkdir -p /tmp/kasm-cache
            cd /tmp/kasm-cache

            # Centos7
            sudo yum makecache
            echo "======== Install Mate destop ==========="
            sudo yum groupinstall -y "MATE Desktop"
            sudo yum install -y epel-release
            echo "======== Install Kasmvnc ==========="
            sudo yum install -y mesa-libGL libXfont2 libXtst pixman perl-Hash-Merge-Simple
            sudo yum install -y libGL.so.1 libX11.so.6 libXau.so.6 libXcursor.so.1 libXext.so.6 \
            libXfixes.so.3 libXfont2.so.2 libXrandr.so.2 libXtst.so.6 libpixman-1.so.0 \
            perl-Data-Dumper perl-Hash-Merge-Simple perl-Switch perl-YAML-Tiny \
            xkeyboard-config xorg-x11-server-utils xorg-x11-xauth xorg-x11-xkb-utils \
            perl-DateTime perl-DateTime-TimeZone wget expect
            
            wget https://github.com/kasmtech/KasmVNC/releases/download/v${KASM_VERSION}/kasmvncserver_centos_core_${KASM_VERSION}_x86_64.rpm
            
            sudo rpm -ivh kasmvncserver_centos_core_${KASM_VERSION}_x86_64.rpm
            sudo usermod -aG kasmvnc-cert $USER || true
   
            sudo yum install -y firewalld
            sudo systemctl enable firewalld
            # Allow vnc
            sudo firewall-cmd --add-port=8444/tcp
            sudo firewall-cmd --add-port=8444/tcp --permanent
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

echo "========== Create user with read and write permisison =================="
echo -e "$KASM_VNC_PASSWD\n$KASM_VNC_PASSWD\n" | vncpasswd -u $USER -w -r
echo "========== User created =================="

# Writing VNC server configuration to file
mkdir -p /home/$USER/.vnc
cat > /home/$USER/.vnc/kasmvnc.yaml << EOL
network:
  protocol: http
  ssl:
    require_ssl: false
  udp:
    public_ip: 127.0.0.1
EOL



PASSWD_PATH="/home/$USER/.kasmpasswd"
if [[ -f $PASSWD_PATH ]]; then
    echo -e "\n---------  purging existing VNC password settings  ---------"
    rm -f $PASSWD_PATH
fi

echo -e "${KASM_VNC_PASSWD}\n${KASM_VNC_PASSWD}\n" | kasmvncpasswd -u $USER -wo
chmod 600 $PASSWD_PATH

# Setting up systemd service for VNC server
cat > vncserver@:1.service << EOL
[Unit]
Description=Remote desktop service (VNC)
After=syslog.target network.target

[Service]
Type=forking
User=administrator
ExecStartPre=/bin/sh -c '/usr/bin/vncserver -kill %i  > /dev/null 2>&1 || :'
ExecStart=/usr/bin/vncserver -disableBasicAuth %i
ExecStop=/usr/bin/vncserver -kill %i

[Install]
WantedBy=default.target
EOL
sudo mv vncserver@:1.service /etc/systemd/system/vncserver@:1.service
sudo systemctl daemon-reload
echo "========== Enable VNC service =================="

sudo systemctl enable vncserver@:1.service
sudo chown -R $USER:$USER /home/$USER/.vnc

sudo rm -rf /tmp/kasm-cache

echo "========== Completed =================="
exit

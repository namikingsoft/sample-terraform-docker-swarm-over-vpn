#!/bin/bash -e

# variable
source /tmp/tfvars
VPN_SELF_IP=$(
  ip addr show vpn_vlan0 \
  | grep -o -e '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' \
  | head -n1
)

# package
apt-get install -y curl zip

# install
cd /tmp
curl -LO https://releases.hashicorp.com/consul/0.6.1/consul_0.6.1_linux_amd64.zip
unzip consul_0.6.1_linux_amd64.zip -d /usr/local/bin
curl -LO https://releases.hashicorp.com/consul/0.6.1/consul_0.6.1_web_ui.zip
mkdir -p /var/local/consul
unzip consul_0.6.1_web_ui.zip -d /var/local/consul/webui

# service
cat << EOS > /lib/systemd/system/consul.service
[Unit]
Description=consul agent
After=network-online.target

[Service]
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d
Type=simple
Restart=always

[Install]
WantedBy=multi-user.target
EOS

# setting
mkdir -p /etc/consul.d
if [ "$NODE_INDEX" = "0" ]; then
cat << EOS > /etc/consul.d/config.json
{
  "server": true,
  "bootstrap": true,
  "bind_addr": "$VPN_SELF_IP",
  "node_name": "swarm-node$NODE_INDEX",
  "datacenter": "swarm0",
  "ui_dir": "/var/local/consul/webui",
  "data_dir": "/var/local/consul/data",
  "log_level": "INFO",
  "enable_syslog": true
}
EOS
else
cat << EOS > /etc/consul.d/config.json
{
  "server": false,
  "start_join": ["$VPN_MASTERIP"],
  "bind_addr": "$VPN_SELF_IP",
  "node_name": "swarm-node$NODE_INDEX",
  "datacenter": "swarm0",
  "ui_dir": "/var/local/consul/webui",
  "data_dir": "/var/local/consul/data",
  "log_level": "INFO",
  "enable_syslog": true
}
EOS
fi

# start
systemctl enable consul
systemctl start consul

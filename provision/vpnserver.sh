#!/bin/bash -e

# variable
source /tmp/tfvars

# exit if not master
if [ "$NODE_INDEX" != "0" ]; then
  exit 0
fi

# install package
apt-get install -y curl gcc make

# download
cd /usr/local/src
curl -LO http://jp.softether-download.com/files/softether/v4.19-9599-beta-2015.10.19-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.19-9599-beta-2015.10.19-linux-x64-64bit.tar.gz
tar xzf softether-vpnserver-v4.19-9599-beta-2015.10.19-linux-x64-64bit.tar.gz
rm softether-vpnserver-v4.19-9599-beta-2015.10.19-linux-x64-64bit.tar.gz

# make
cd vpnserver
make i_read_and_agree_the_license_agreement
echo 'export PATH="/usr/local/src/vpnserver:$PATH"' >> /etc/profile
PATH="/usr/local/src/vpnserver:$PATH"

# service
cat << EOS > /lib/systemd/system/vpnserver.service
[Unit]
Description=SoftEther VPN Server
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/src/vpnserver/vpnserver start
ExecStop=/usr/local/src/vpnserver/vpnserver stop

[Install]
WantedBy=multi-user.target
EOS

# run
systemctl enable vpnserver
systemctl start vpnserver

# setting
HUBNAME=cluster
HUBPASS=password
USERNAME="$VPN_USERNAME"
USERPASS="$VPN_PASSWORD"
SHAREDKEY=sharedkey
while true; do
  sleep 1
  vpncmd localhost /SERVER /CMD HubCreate $HUBNAME \
    /PASSWORD:$HUBPASS && true
  if [ "$?" = "0" ]; then
    break
  fi
done
vpncmd localhost /SERVER /HUB:$HUBNAME /PASSWORD:$HUBPASS /CMD \
  SecureNatEnable
vpncmd localhost /SERVER /HUB:$HUBNAME /PASSWORD:$HUBPASS /CMD \
  UserCreate $USERNAME \
  /GROUP:none \
  /REALNAME:none \
  /NOTE:none
vpncmd localhost /SERVER /HUB:$HUBNAME /PASSWORD:$HUBPASS /CMD \
  UserPasswordSet $USERNAME \
  /PASSWORD:$USERPASS
vpncmd localhost /SERVER /CMD \
  IPsecEnable \
  /L2TP:yes \
  /L2TPRAW:no \
  /ETHERIP:yes \
  /PSK:$SHAREDKEY \
  /DEFAULTHUB:$HUBNAME

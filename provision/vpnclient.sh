#!/bin/bash -e

# arguments
ID=$1
MASTER_IP=$2

# install package
apt-get install -y curl gcc make

# download
cd /usr/local/src
curl -LO http://jp.softether-download.com/files/softether/v4.19-9599-beta-2015.10.19-tree/Linux/SoftEther_VPN_Client/64bit_-_Intel_x64_or_AMD64/softether-vpnclient-v4.19-9599-beta-2015.10.19-linux-x64-64bit.tar.gz
tar xzf softether-vpnclient-v4.19-9599-beta-2015.10.19-linux-x64-64bit.tar.gz
rm softether-vpnclient-v4.19-9599-beta-2015.10.19-linux-x64-64bit.tar.gz

# make
cd vpnclient
make i_read_and_agree_the_license_agreement
echo 'export PATH="/usr/local/src/vpnclient:$PATH"' >> /etc/profile
PATH="/usr/local/src/vpnclient:$PATH"

# service
cat << EOS > /lib/systemd/system/vpnclient.service
[Unit]
Description=SoftEther VPN Client
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/src/vpnclient/vpnclient start
ExecStop=/usr/local/src/vpnclient/vpnclient stop

[Install]
WantedBy=multi-user.target
EOS

# run
systemctl enable vpnclient
systemctl start vpnclient

# setting
ACCOUNT=cluster
NICNAME=vlan0
SERVER="$MASTER_IP:443"
HUBNAME=cluster
USERNAME=user
USERPASS=something
while true; do
  sleep 1
  vpncmd localhost /CLIENT /CMD RemoteDisable
  if [ "$?" = "0" ]; then
    break
  fi
done
vpncmd localhost /CLIENT /CMD NicCreate $NICNAME
vpncmd localhost /CLIENT /CMD AccountCreate $ACCOUNT \
  /SERVER:$SERVER \
  /HUB:$HUBNAME \
  /USERNAME:$USERNAME \
  /NICNAME:$NICNAME
vpncmd localhost /CLIENT /CMD AccountPasswordSet $ACCOUNT \
  /PASSWORD:$USERPASS \
  /TYPE:standard
vpncmd localhost /CLIENT /CMD AccountStartupSet $ACCOUNT
vpncmd localhost /CLIENT /CMD AccountConnect $ACCOUNT

# add ip
if [ "$ID" != "0" ]; then
  dhclient vpn_$NICNAME
else
  ip addr add 192.168.30.2/24 dev vpn_$NICNAME
fi

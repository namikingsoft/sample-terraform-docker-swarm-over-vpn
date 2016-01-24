#!/bin/bash -e

# arguments
ID=$1
IP=$(
  ip addr show vpn_vlan0 \
  | grep -o -e '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' \
  | head -n1
)

# install docker
echo "Installing docker ..."
wget -qO- https://get.docker.com/ | sh

# setting docker
iptables -A INPUT -i eth0 -p tcp -m tcp --dport 2375 -j DROP
iptables -A INPUT -i eth0 -p tcp -m tcp --dport 3375 -j DROP
DOCKER_OPTS="-H=0.0.0.0:2375 --cluster-store=consul://localhost:8500 --cluster-advertise=vpn_vlan0:2375"
sed -i "s;docker daemon;docker daemon ${DOCKER_OPTS};" \
  /lib/systemd/system/docker.service
systemctl daemon-reload
service docker restart

# swarm manager
if [ "$ID" = "0" ]; then
  docker run -d --name=swarm-agent-master \
    -v=/etc/docker:/etc/docker --net=host --restart=always\
    swarm manage -H=0.0.0.0:3375 --strategy=spread --advertise=${IP}:2375 consul://localhost:8500
fi

# swarm agent
docker run -d --name swarm-agent --net=host --restart=always \
  swarm join --advertise=${IP}:2375 consul://localhost:8500

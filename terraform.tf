variable "do_token" {}
variable "pub_key" {}
variable "pvt_key" {}
variable "ssh_fingerprint" {}
variable "vpn_masterip" {}
variable "vpn_username" {}
variable "vpn_password" {}

provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_droplet" "node" {
  image = "ubuntu-15-10-x64"
  name = "swarm-node${count.index}"
  region = "sgp1"
  size = "512mb"
  count = 1
  private_networking = false
  ssh_keys = [
    "${var.ssh_fingerprint}"
  ]
  connection {
    user = "root"
    type = "ssh"
    key_file = "${var.pvt_key}"
    timeout = "2m"
  }
  provisioner "file" {
    source = "provision/consul.sh"
    destination = "/tmp/consul.sh"
  }
  provisioner "file" {
    source = "provision/docker.sh"
    destination = "/tmp/docker.sh"
  }
  provisioner "file" {
    source = "provision/vpnserver.sh"
    destination = "/tmp/vpnserver.sh"
  }
  provisioner "file" {
    source = "provision/vpnclient.sh"
    destination = "/tmp/vpnclient.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "echo NODE_INDEX='${count.index}' > /tmp/tfvars",
      "echo VPN_MASTERIP='${var.vpn_masterip}' >> /tmp/tfvars",
      "echo VPN_USERNAME='${var.vpn_username}' >> /tmp/tfvars",
      "echo VPN_PASSWORD='${var.vpn_password}' >> /tmp/tfvars",
      "echo SELF_GLOBAL_IP='${self.ipv4_address}' >> /tmp/tfvars",
      "echo MASTER_GLOBAL_IP='${digitalocean_droplet.node.0.ipv4_address}' >> /tmp/tfvars",
      "chmod +x /tmp/*.sh",
      "/tmp/vpnserver.sh",
      "/tmp/vpnclient.sh",
      "/tmp/consul.sh",
      "/tmp/docker.sh",
      "rm /tmp/tfvars /tmp/*.sh",
    ]
  }
}

variable "do_token" {}
variable "pub_key" {}
variable "pvt_key" {}
variable "ssh_fingerprint" {}
variable "vpn_master_ip" {}

provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_droplet" "node" {
  image = "ubuntu-15-10-x64"
  name = "swarm-node${count.index}"
  region = "sgp1"
  size = "512mb"
  count = 2
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
      "chmod +x /tmp/*.sh",
      "/tmp/vpnserver.sh ${count.index}",
      "/tmp/vpnclient.sh ${count.index} ${digitalocean_droplet.node.0.ipv4_address}",
      "/tmp/consul.sh ${count.index } ${var.vpn_master_ip}",
      "/tmp/docker.sh ${count.index} ${self.ipv4_address}",
    ]
  }
}

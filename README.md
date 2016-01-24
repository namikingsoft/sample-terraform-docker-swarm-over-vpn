Build docker swarm over VPN  using Terraform
==============================
This is sample build docker swarm cluster over VPN using Terraform on DigitalOcean.

Refs: [クラウドとローカルをVPNでガッチャンコしたDockerネットワークを組んでみる](http://blog.namiking.net/post/2016/01/docker-swarm-over-vpn/)

Get Started
------------------------------

#### setting
```sh
cp terraform.tfvars.sample terraform.tfvars
vi terraform.tfvars
```

#### plan and apply
```sh
terraform plan
terraform apply
```


License
------------------------------
[MIT](./LICENSE)

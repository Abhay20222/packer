packer {
  required_plugins {
    amazon = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}
source "amazon-ebs" "packer-ami-abhay-node" {
  ami_name      = "packer-ami-abhay-nodejs"
  source_ami    = "ami-0ada6d94f396377f2"
  instance_type = "t3a.small"
  region        = "us-east-2"
  ssh_username  = "ubuntu"
}
build {
  sources = [
    "source.amazon-ebs.packer-ami-abhay-node"
  ]
  provisioner "shell" {
    script = "./app.sh"
  }
}

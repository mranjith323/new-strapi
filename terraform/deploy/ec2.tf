data "aws_ami" "ubuntu" {
     most_recent = true
     filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
 }

     filter {
       name   = "virtualization-type"
       values = ["hvm"]
 }

     owners = ["099720109477"]

 }

 resource "aws_security_group" "strapi-security-grp" {
  name        = "strapi-security-grp"
  description = "Allow TLS inbound traffic1"

  ingress {
    description      = "TLS from VPC"
    from_port        = 1337
    to_port          = 1337
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

    ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "strapi-security-grp"
  }
}

# resource "tls_private_key" "key_pair" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "aws_key_pair" "key" {
#   key_name   = "strapi-key"
#   public_key = tls_private_key.key_pair.public_key_openssh
# }

# resource "local_file" "pem_file" {
#   filename          = pathexpand("./pem/strapi-key.pem")
#   file_permission   = "400"
#   sensitive_content = tls_private_key.key_pair.private_key_pem
# }

resource "aws_instance" "strapi-server" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3a.small"
  key_name = "taskkey.pem"
  vpc_security_group_ids = [aws_security_group.strapi-security-grp.id]

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "curl -sL https://deb.nodesource.com/setup_18.x -o nodesource_setup.sh",
      "sudo bash nodesource_setup.sh",
      "sudo apt install nodejs -y",
      "sudo apt install npm -y",
      "sudo npm install pm2@latest -g",
      "cd /srv/",
      "sudo chown -R ubuntu:ubuntu /srv",
      "git clone https://github.com/mranjith323/new-strapi.git strapi",
      "cd strapi",
      "cp .env.example .env",
      "npm install",
      "npm run build",
      "pm2 start npm --name 'strapi' -- start",
      "pm2 save",
      "pm2 startup",
      "sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "taskkey.pem"
    host        = self.public_ip
  }

  tags = {
    Name = "StrapiServer"
  }   
}
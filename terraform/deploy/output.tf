output "instance_ip" {
  value = aws_instance.strapi-server.public_ip
}
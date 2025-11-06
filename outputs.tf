output "vm1_public_ip" {
  value = aws_instance.VM1.public_ip
}

output "vm2_public_ip" {
  value = aws_instance.VM2.public_ip
}

output "vm1_private_ip" {
  value = aws_instance.VM1.private_ip
}

output "vm2_private_ip" {
  value = aws_instance.VM2.private_ip
}


resource "aws_key_pair" "vpc-key" {
  key_name   = "vpc-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
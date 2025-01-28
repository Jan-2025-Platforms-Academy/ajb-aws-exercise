resource "aws_key_pair" "ajb" {
  key_name   = "${var.name}-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
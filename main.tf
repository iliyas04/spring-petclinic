provider "aws" {
  region = "us-east-1"
}
resource "aws_instance" "tomcat_server" {
  ami           = "ami-020cba7c55df1f615"
  instance_type = "t2.micro"
  security_groups = ["sgalltraffic"]  # Reference the existing security group
  key_name      = "mujahed"
}


output  "tomcat_server_ip" {
  value = aws_instance.tomcat_server.public_ip
}

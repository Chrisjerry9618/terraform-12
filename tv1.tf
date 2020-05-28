provider  "aws" {
  region     = "us-east-1"
  access_key = "AKIA4KFLI5323WOGODDF"
  secret_key = "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"
}
variable "aws_subnet" {
  #default = "us-east-1a"
}
variable "aws_subnet1b" {
  #default = "us-east-1b" 
}
resource "aws_vpc" "chris-test" {
   cidr_block = "10.0.0.0/16"

    tags = {
    Name = "chris-test"
  }
}
resource "aws_subnet" "public-subnet" {
   vpc_id     = aws_vpc.chris-test.id
   cidr_block = "10.0.1.0/24"
   map_public_ip_on_launch = "true"
   availability_zone = var.aws_subnet

   tags = { Name = "chris-test-subnet1" }
}
resource "aws_subnet" "public-subnet1" {
   vpc_id     = aws_vpc.chris-test.id
   cidr_block = "10.0.2.0/24"
   map_public_ip_on_launch = "true"
   availability_zone = var.aws_subnet1b

   tags = { Name = "chris-test-subnet2" }
}
resource "aws_internet_gateway" "chris-igw" {
  vpc_id = aws_vpc.chris-test.id

  tags = {
    Name = "chris-igw"
  }
}
resource "aws_route_table" "publicroute" {
  vpc_id = aws_vpc.chris-test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.chris-igw.id
}
  tags = {
    Name = "publicroute"
  }
}
resource "aws_route_table_association" "publicsubnets" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.publicroute.id
}
resource "aws_route_table_association" "publicsubnets2" {
  subnet_id      = aws_subnet.public-subnet1.id
  route_table_id = aws_route_table.publicroute.id
}
resource "aws_security_group" "sg" {
  name        = "web-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.chris-test.id
  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["183.82.251.22/32", "52.76.93.21/32"] # add a CIDR block here
  }
}
resource "aws_instance" "ec2" {
  subnet_id = aws_subnet.public-subnet.id
  key_name = "chris-devops"
  instance_type = "t2.micro"
  ami = "ami-085925f297f89fce1"
  vpc_security_group_ids = [aws_security_group.sg.id]
}
resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = [aws_subnet.public-subnet.id,aws_subnet.public-subnet1.id]

  tags = {
    Environment = "production"
  }
}
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.test.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target.arn
  }
}
resource "aws_lb_target_group" "target" {
  name     = "test-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.chris-test.id
}

resource "aws_lb_target_group_attachment" "register" {
  target_group_arn = aws_lb_target_group.target.arn
 target_id        = aws_instance.ec2.id
  port             = 80
}

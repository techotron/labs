data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc" {
  cidr_block                = "10.0.0.0/16"
    enable_dns_hostnames    = true
    enable_dns_support      = true

  tags = {
    Name                    = "terraform_vpc"
    built_by                = "terraform"
  }
}

resource "aws_subnet" "public" {
  count                     = "${length(var.public_subnet)}"
  vpc_id                    = "${aws_vpc.vpc.id}"
  cidr_block                = "${var.public_subnet[count.index]}"
  availability_zone         = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch   = true

  tags = {
    Name                    = "terraform_subnet"
    built_by                = "terraform"
    subnet_type             = "public"
  }
}

resource "aws_subnet" "private" {
  count                     = "${length(var.private_subnet)}"
  vpc_id                    = "${aws_vpc.vpc.id}"
  cidr_block                = "${var.private_subnet[count.index]}"
  availability_zone         = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch   = false

  tags = {
    Name                    = "terraform_subnet"
    built_by                = "terraform"
    subnet_type             = "private"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id                    = "${aws_vpc.vpc.id}"

  tags = {
    Name                    = "terraform_gateway"
    built_by                = "terraform"
  }
}

resource "aws_route_table" "route" {
  vpc_id                    = "${aws_vpc.vpc.id}"

  route {
    cidr_block              = "0.0.0.0/0"
    gateway_id              = "${aws_internet_gateway.gateway.id}"
  }

  tags = {
    Name                    = "terraform_route"
    built_by                = "terraform"
  }
}

resource "aws_security_group" "allow_ssh" {
  name                      = "allow_ssh"
  description               = "Allow SSH inbound traffic"
  vpc_id                    = "${aws_vpc.vpc.id}"

  ingress {
    from_port               = 22
    to_port                 = 22
    protocol                = "tcp"
    cidr_blocks             = ["0.0.0.0/0"]
  }

  tags = {
    Name                    = "terraform_security_group"
    built_by                = "terraform"
  }
}
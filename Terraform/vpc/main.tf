data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc" {
  cidr_block                = "10.0.0.0/16"
    enable_dns_hostnames    = true
    enable_dns_support      = true

  tags = {
    Name                    = "${var.app}_vpc"
    built_by                = "terraform"
  }
}

# Below is an example of looping through a list. It was a pain to manage when I wanted to reference
# subnets in other tf resources.

# resource "aws_subnet" "public" {
#   count                     = "${length(var.public_subnet)}"
#   vpc_id                    = "${aws_vpc.vpc.id}"
#   cidr_block                = "${var.public_subnet[count.index]}"
#   availability_zone         = "${data.aws_availability_zones.available.names[count.index]}"
#   map_public_ip_on_launch   = true

#   tags = {
#     Name                    = "${var.app}_subnet"
#     built_by                = "terraform"
#     subnet_type             = "public"
#   }
# }

# resource "aws_subnet" "private" {
#   count                     = "${length(var.private_subnet)}"
#   vpc_id                    = "${aws_vpc.vpc.id}"
#   cidr_block                = "${var.private_subnet[count.index]}"
#   availability_zone         = "${data.aws_availability_zones.available.names[count.index]}"
#   map_public_ip_on_launch   = false

#   tags = {
#     Name                    = "${var.app}_subnet"
#     built_by                = "terraform"
#     subnet_type             = "private"
#   }
# }

resource "aws_subnet" "public_a" {
  vpc_id                    = aws_vpc.vpc.id
  cidr_block                = var.public_subnet_a
  availability_zone         = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch   = true

  tags = {
    Name                    = "${var.app}_subnet"
    built_by                = "terraform"
    subnet_type             = "public"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                    = aws_vpc.vpc.id
  cidr_block                = var.public_subnet_b
  availability_zone         = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch   = true

  tags = {
    Name                    = "${var.app}_subnet"
    built_by                = "terraform"
    subnet_type             = "public"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id                    = aws_vpc.vpc.id
  cidr_block                = var.private_subnet_a
  availability_zone         = data.aws_availability_zones.available.names[0]

  tags = {
    Name                    = "${var.app}_subnet"
    built_by                = "terraform"
    subnet_type             = "private"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                    = aws_vpc.vpc.id
  cidr_block                = var.private_subnet_b
  availability_zone         = data.aws_availability_zones.available.names[1]

  tags = {
    Name                    = "${var.app}_subnet"
    built_by                = "terraform"
    subnet_type             = "private"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id                    = aws_vpc.vpc.id

  tags = {
    Name                    = "${var.app}_gateway"
    built_by                = "terraform"
  }
}

resource "aws_route_table" "route" {
  vpc_id                    = aws_vpc.vpc.id

  route {
    cidr_block              = "0.0.0.0/0"
    gateway_id              = aws_internet_gateway.gateway.id
  }

  tags = {
    Name                    = "${var.app}_route"
    built_by                = "terraform"
  }
}

resource "aws_security_group" "allow_ssh" {
  name                      = "allow_ssh"
  description               = "Allow SSH inbound traffic"
  vpc_id                    = aws_vpc.vpc.id

  ingress {
    from_port               = 22
    to_port                 = 22
    protocol                = "tcp"
    cidr_blocks             = ["0.0.0.0/0"]
  }

  tags = {
    Name                    = "${var.app}_ssh_allow"
    built_by                = "terraform"
  }
}

resource "aws_security_group" "public_allow" {
  name                      = "public_allow"
  description               = "Allow standard web ports"
  vpc_id                    = aws_vpc.vpc.id

  ingress {
    from_port               = 80
    to_port                 = 80
    protocol                = "tcp"
    cidr_blocks             = ["0.0.0.0/0"]
  }

  ingress {
    from_port               = 8080
    to_port                 = 8080
    protocol                = "tcp"
    cidr_blocks             = ["0.0.0.0/0"]
  }

  ingress {
    from_port               = 443
    to_port                 = 443
    protocol                = "tcp"
    cidr_blocks             = ["0.0.0.0/0"]
  }  

  egress {
      # allow all traffic to private SN
      from_port             = "0"
      to_port               = "0"
      protocol              = "-1"
      cidr_blocks           = [
        "0.0.0.0/0"
      ]
  }

  tags = {
    Name                    = "${var.app}_public_allow"
    built_by                = "terraform"
  }  
}

resource "aws_security_group" "internal_allow" {
  name                      = "internal_allow"
  description               = "Allow traffic between subnets"
  vpc_id                    = aws_vpc.vpc.id

  ingress {
    from_port               = 0
    to_port                 = 0
    protocol                = "tcp"
    cidr_blocks             = [
      var.public_subnet_a,
      var.public_subnet_b,
      var.private_subnet_a,
      var.private_subnet_b
    ]
  }
  
  tags = {
    Name                    = "${var.app}_internal_allow"
    built_by                = "terraform"
  }  
}

# Create a new instance of the latest Ubuntu 14.04 on an
# t2.micro node with an AWS Tag naming it "HelloWorld"

data "aws_ami" "amazon-linux-2" {
 most_recent = true


 filter {
   name   = "owner-alias"
   values = [ "amazon" ]
 }

 owners = [ "amazon" ]


 filter {
   name   = "name"
   values = [ "amzn2-ami-hvm*" ]
 }
}

resource "aws_instance" "server" {
  ami           = "${data.aws_ami.amazon-linux-2.id}"
  instance_type = "t2.micro"
  key_name      = "snowco"
  subnet_id     = 

  tags = {
    Name        = "simple-ec2"
    build_type  = "terraform"
  }
}

resource "aws_alb" "ecs-load-balancer" {
  name = "ecs-load-balancer"
  security_groups = ["${aws_security_group.public_allow.id}"]
  subnets = ["${aws_subnet.public_subnet_a.id}", "${aws_subnet.public_subnet_b.id}"]

  tags {
    Name                    = "${var.app}_alb"
    built_by                = "terraform"
  }
}

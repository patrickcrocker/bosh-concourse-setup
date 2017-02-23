# Create a Concourse security group
resource "aws_security_group" "concourse-sg" {
  name        = "concourse-sg"
  description = "Concourse security group"
  vpc_id      = "${aws_vpc.default.id}"
  tags {
  Name = "concourse-sg"
  component = "concourse"
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # inbound connections from ELB
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = ["${aws_security_group.elb-sg.id}"]
  }

  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    security_groups = ["${aws_security_group.elb-sg.id}"]
  }
}

# Create an ELB security group
resource "aws_security_group" "elb-sg" {
  name        = "elb-sg"
  description = "ELB security group"
  vpc_id      = "${aws_vpc.default.id}"
  tags {
  Name = "elb-sg"
  component = "concourse"
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # inbound https
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # inbound https
  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Create a new load balancer
resource "aws_elb" "concourse" {
  name = "concourse-elb"
  subnets = ["${aws_subnet.ops_services.id}"]
  security_groups = ["${aws_security_group.elb-sg.id}"]

  listener {
    instance_port = 8080
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  listener {
    instance_port = 8080
    instance_protocol = "tcp"
    lb_port = 443
    lb_protocol = "ssl"
    ssl_certificate_id = "${var.ssl_cert_arn}"
}

  listener {
    instance_port = 2222
    instance_protocol = "tcp"
    lb_port = 2222
    lb_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    target = "TCP:2222"
    interval = 15
    timeout = 5
  }

  tags {
  component = "concourse"
  }
}

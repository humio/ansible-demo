provider "aws" {}

data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.aws_ami_filter}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

//  owners = ["099720109477"]
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "humio" {
  cidr_block = "${var.aws_vpc_cidr_block}"
  enable_dns_hostnames = true
}

resource "aws_security_group" "main" {
  name        = "${var.aws_name_prefix}allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = "${aws_vpc.humio.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "zookeepers" {
  name        = "zookeepers"
  description = "Allow Zookeeper inbound traffic"
  vpc_id      = "${aws_vpc.humio.id}"

  ingress {
    from_port   = 2181
    to_port     = 2181
    protocol    = "TCP"
    cidr_blocks = ["${aws_vpc.humio.cidr_block}"]
  }

  ingress {
    from_port   = 2888
    to_port     = 2888
    protocol    = "TCP"
    cidr_blocks = ["${aws_vpc.humio.cidr_block}"]
  }

  ingress {
    from_port   = 3888
    to_port     = 3888
    protocol    = "TCP"
    cidr_blocks = ["${aws_vpc.humio.cidr_block}"]
  }
}

resource "aws_security_group" "kafkas" {
  name        = "kafkas"
  description = "Allow Kafka inbound traffic"
  vpc_id      = "${aws_vpc.humio.id}"

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "TCP"
    cidr_blocks = ["${aws_vpc.humio.cidr_block}"]
  }
}

resource "aws_security_group" "humios" {
  name        = "humios"
  description = "Allow Humio inbound traffic"
  vpc_id      = "${aws_vpc.humio.id}"

  ingress {
    from_port   = 8080
    to_port     = 8081
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9200
    to_port     = 9201
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ui-public" {
  name        = "humio-ui-public"
  description = "Allow humio public trafic"
  vpc_id      = "${aws_vpc.humio.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["${aws_vpc.humio.cidr_block}"]
  }
}

resource "aws_security_group" "ingest-public" {
  name        = "humio-ingest-public"
  description = "Allow humio public trafic"
  vpc_id      = "${aws_vpc.humio.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["${aws_vpc.humio.cidr_block}"]
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.humio.id}"
}

resource "aws_route_table" "route_table" {
  vpc_id = "${aws_vpc.humio.id}"
}

resource "aws_route" "internet_route" {
  route_table_id = "${aws_route_table.route_table.id}"
  gateway_id = "${aws_internet_gateway.internet_gateway.id}"
  destination_cidr_block = "0.0.0.0/0"
}
resource "aws_route_table_association" "route_table_association" {
  route_table_id = "${aws_route_table.route_table.id}"
  subnet_id = "${aws_subnet.public_subnet_primary.id}"
}

resource "aws_subnet" "public_subnet_primary" {
  vpc_id = "${aws_vpc.humio.id}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  cidr_block = "${cidrsubnet(aws_vpc.humio.cidr_block, 8, 10)}"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "public_subnet_secondary" {
  vpc_id = "${aws_vpc.humio.id}"
  cidr_block = "${cidrsubnet(aws_vpc.humio.cidr_block, 8, 20)}"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  map_public_ip_on_launch = true
}

resource "aws_lb" "ui" {
  name = "humio-ui"
  internal = false
  load_balancer_type = "application"
  subnets = ["${aws_subnet.public_subnet_primary.id}", "${aws_subnet.public_subnet_secondary.id}"]
  security_groups = ["${aws_security_group.ui-public.id}"]
}

resource "aws_lb" "ingest" {
  name = "humio-ingest"
  internal = false
  load_balancer_type = "application"
  subnets = ["${aws_subnet.public_subnet_primary.id}", "${aws_subnet.public_subnet_secondary.id}"]
  security_groups = ["${aws_security_group.ingest-public.id}"]
}

resource "aws_lb_target_group" "ui-http" {
  name = "humio-ui"
  port = 8080
  protocol = "HTTP"
  vpc_id = "${aws_vpc.humio.id}"
  health_check {
    path = "/api/v1/status"
  }
  stickiness {
    type = "lb_cookie"
  }
}

resource "aws_lb_target_group" "ingest-api" {
  name = "humio-ingest-api"
  port = 8080
  protocol = "HTTP"
  vpc_id = "${aws_vpc.humio.id}"
  health_check {
    path = "/api/v1/status"
  }
}

resource "aws_lb_target_group" "ingest-es" {
  name = "humio-ingest-es"
  port = 9200
  protocol = "HTTP"
  vpc_id = "${aws_vpc.humio.id}"
  health_check {
    path = "/_bulk"
    matcher = "200-499"
  }
}

resource "aws_lb_listener" "humio-ui-http" {
  load_balancer_arn = "${aws_lb.ui.arn}"
  port = 80
  protocol = "HTTP"

  "default_action" {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.ui-http.arn}"
  }
}

resource "aws_lb_listener" "humio-ingest-http" {
  load_balancer_arn = "${aws_lb.ingest.arn}"
  port = 80
  protocol = "HTTP"

  "default_action" {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.ingest-api.arn}"
  }
}
resource "aws_lb_listener" "humio-ingest-es" {
  load_balancer_arn = "${aws_lb.ingest.arn}"
  port = 9200
  protocol = "HTTP"

  "default_action" {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.ingest-es.arn}"
  }
}

resource "aws_network_interface" "zkh-nic" {
  count = "${var.zkh_instances}"
  subnet_id = "${aws_subnet.public_subnet_primary.id}"
  private_ips = ["${cidrhost(aws_subnet.public_subnet_primary.cidr_block, 10+count.index)}"]
  security_groups = ["${aws_security_group.main.id}", "${aws_security_group.zookeepers.id}", "${aws_security_group.kafkas.id}", "${aws_security_group.humios.id}"] //TODO: Replace humio_security_group with ELBs
}

resource "aws_instance" "zk-kafka-humios" {
  count = "${var.zkh_instances}"
  ami = "${data.aws_ami.ami.image_id}"
  instance_type = "${var.humio_plan}"
  key_name = "${var.aws_key_name}"

  user_data = <<USERDATA
#!/bin/bash
test -e /usr/bin/python || (apt -y update && apt install -y python-minimal python-apt)
USERDATA

  network_interface {
    device_index = 0
    network_interface_id = "${element(aws_network_interface.zkh-nic.*.id, count.index)}"
  }

  tags {
    Name = "${format("humio%02d", count.index + 1)}"
    cluster_index = "${count.index + 1}"
  }
}

resource "aws_lb_target_group_attachment" "zkh-ui-0" {
  target_group_arn = "${aws_lb_target_group.ui-http.arn}"
  target_id = "${element(aws_instance.zk-kafka-humios.*.id, count.index)}"
  port = 8080
  count = "${var.zkh_instances}"
}
resource "aws_lb_target_group_attachment" "zkh-ui-1" {
  target_group_arn = "${aws_lb_target_group.ui-http.arn}"
  target_id = "${element(aws_instance.zk-kafka-humios.*.id, count.index)}"
  port = 8081
  count = "${var.zkh_instances}"
}
resource "aws_lb_target_group_attachment" "zkh-ingest-http-0" {
  target_group_arn = "${aws_lb_target_group.ingest-api.arn}"
  target_id = "${element(aws_instance.zk-kafka-humios.*.id, count.index)}"
  port = 8080
  count = "${var.zkh_instances}"
}
resource "aws_lb_target_group_attachment" "zkh-ingest-http-1" {
  target_group_arn = "${aws_lb_target_group.ingest-api.arn}"
  target_id = "${element(aws_instance.zk-kafka-humios.*.id, count.index)}"
  port = 8081
  count = "${var.zkh_instances}"
}
resource "aws_lb_target_group_attachment" "zkh-ingest-es-0" {
  target_group_arn = "${aws_lb_target_group.ingest-es.arn}"
  target_id = "${element(aws_instance.zk-kafka-humios.*.id, count.index)}"
  port = 9200
  count = "${var.zkh_instances}"
}
resource "aws_lb_target_group_attachment" "zkh-ingest-es-1" {
  target_group_arn = "${aws_lb_target_group.ingest-es.arn}"
  target_id = "${element(aws_instance.zk-kafka-humios.*.id, count.index)}"
  port = 9201
  count = "${var.zkh_instances}"
}

resource "aws_network_interface" "kh-nic" {
  count = "${var.kh_instances}"
  subnet_id = "${aws_subnet.public_subnet_primary.id}"
  private_ips = ["${cidrhost(aws_subnet.public_subnet_primary.cidr_block, 10+var.zkh_instances+count.index)}"]
  security_groups = ["${aws_security_group.main.id}", "${aws_security_group.kafkas.id}", "${aws_security_group.humios.id}"] //TODO: Replace humio_security_group with ELBs
}

resource "aws_instance" "kafka-humios" {
  count = "${var.kh_instances}"
  ami = "${data.aws_ami.ami.image_id}"
  instance_type = "${var.humio_plan}"
  key_name = "${var.aws_key_name}"

  user_data = <<USERDATA
#!/bin/bash
test -e /usr/bin/python || (apt -y update && apt install -y python-minimal python-apt)
USERDATA

  network_interface {
    device_index = 0
    network_interface_id = "${element(aws_network_interface.kh-nic.*.id, count.index)}"
  }

  tags {
    Name = "${format("humio%02d", var.zkh_instances + count.index + 1)}"
    cluster_index = "${var.zkh_instances + count.index + 1}"
  }
}

resource "aws_lb_target_group_attachment" "kh-ui" {
  target_group_arn = "${aws_lb_target_group.ui-http.arn}"
  target_id = "${element(aws_instance.kafka-humios.*.id, count.index)}"
  count = "${var.kh_instances}"
}
resource "aws_lb_target_group_attachment" "kh-ingest-http" {
  target_group_arn = "${aws_lb_target_group.ingest-api.arn}"
  target_id = "${element(aws_instance.kafka-humios.*.id, count.index)}"
  count = "${var.kh_instances}"
}
resource "aws_lb_target_group_attachment" "kh-ingest-es" {
  target_group_arn = "${aws_lb_target_group.ingest-es.arn}"
  target_id = "${element(aws_instance.kafka-humios.*.id, count.index)}"
  count = "${var.kh_instances}"
}

output "Humio ui" {
  value = "http://${aws_lb.ui.dns_name}"
}

output "Humio ingest API" {
  value = "http://${aws_lb.ingest.dns_name}"
}

output "Humio ingest Elastic" {
  value = "http://${aws_lb.ingest.dns_name}:9200"
}

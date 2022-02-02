
resource "aws_vpc" "dc_vpc" {
    cidr_block = "10.250.0.0/16"

    tags = {
        Name = var.namespace
    }
}

resource "aws_subnet" "dc_subnet" {
    vpc_id      = aws_vpc.dc_vpc.id
    cidr_block  = "10.250.10.0/24"
    availability_zone = "eu-west-1a"

    tags = {
        Name = var.namespace
    }
}

resource "aws_internet_gateway" "dc_igw" {
    vpc_id = aws_vpc.dc_vpc.id

    tags = {
        Name = var.namespace
    }
}

resource "aws_route_table" "dc_rt" {
    vpc_id = aws_vpc.dc_vpc.id

    route {
        cidr_block  = "0.0.0.0/0"
        gateway_id  = aws_internet_gateway.dc_igw.id
    }

    tags = {
        Name = var.namespace
    }
}

resource "aws_route_table_association" "dc_rta" {
    subnet_id       = aws_subnet.dc_subnet.id
    route_table_id  = aws_route_table.dc_rt.id
}

resource "aws_security_group" "allow_rdp" {
    name    = "${var.namespace}_allow_rdp"
    description = "allow RDP inbound"
    vpc_id = aws_vpc.dc_vpc.id

    ingress {
        description     = "RDP from anywhere - TCP"
        from_port       = 0
        to_port         = 3389
        protocol        = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    ingress {
        description     = "RDP from anywhere - UDP"
        from_port       = 0
        to_port         = 3389
        protocol        = "udp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = var.namespace
    }
}

resource "aws_network_interface" "dc_nic" {
    subnet_id   = aws_subnet.dc_subnet.id
    private_ips = ["10.250.10.5"]
    security_groups = [aws_security_group.allow_rdp.id]

    tags = {
        Name = var.namespace
    }
}
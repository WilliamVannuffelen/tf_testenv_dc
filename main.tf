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

resource "aws_key_pair" "dc_key" {
    key_name    = "${var.namespace}_key"
    public_key  = file(var.public_key_path)

    tags = {
        Name = var.namespace
    }
}

resource "aws_instance" "dc" {
    ami             = "ami-0a46adf18f8875ad6"
    instance_type   = "t3.medium"
    key_name        = aws_key_pair.dc_key.key_name
    associate_public_ip_address = true
    get_password_data           = true
    user_data                   = <<EOF
<powershell>
Start-Transcript
# install role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# set NLA
(Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(0)

# set NTP
w32tm /config /manualpeerlist:169.254.169.123 /syncfromflags:manual /update

$params = @{
    domainName                          = "contoso.local"
    domainNetBIOSName                   = "CONTOSO"
    safeModeAdministratorPassword       = "${var.dsrm_password}"
    domainMode                          = "Win2012R2"
    forestMode                          = "Win2012R2"
    installDns                          = $true
    createDNSDelegation                 = $false
    databasePath                        = "C:\Windows\NTDS"
    logPath                             = "C:\Windows\NTDS"
    sysvolPath                          = "C:\Windows\SYSVOL"
}
Install-ADDSForest @params

Stop-Transcript
</powershell>
EOF
    
    network_interface {
        network_interface_id    = aws_network_interface.dc_nic.id
        device_index            = 0
    }

    tags = {
        Name = var.namespace
    }
}
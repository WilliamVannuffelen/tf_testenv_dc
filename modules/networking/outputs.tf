output "dc_subnet" {
    value = aws_subnet.dc_subnet
}

output "dc_sg" {
    value = aws_security_group.allow_rdp
}
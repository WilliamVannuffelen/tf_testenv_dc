output "dc_nic" {
    value       = aws_network_interface.dc_nic.id
    description = "The ID of the NIC to be attached to the instance."
}
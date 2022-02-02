output "dc_public_ip" {
    value = {
        "${aws_instance.dc.id}" = "${aws_instance.dc.public_ip}"
    }
}   

output "admin_pw" {
    value = rsadecrypt(aws_instance.dc.password_data, file(var.private_key_path))
}
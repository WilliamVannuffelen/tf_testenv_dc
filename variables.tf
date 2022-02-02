variable "namespace" {
    description = "Project namespace"
    type        = string
}

variable "dsrm_password" {
    description = "DSRM password"
    type        = string
    sensitive  = true
}

variable "private_key_path" {
    description = "Path to private key for password decryption"
    type        = string
}

variable "public_key_path" {
    description = "Path to public key for password decryption"
    type        = string
}
provider "aws" {
  region     = "ap-northeast-1"
}

variable "ami" {
    default = "ami-3bd3c45c"
}

variable "myip" {
    default = "0.0.0.0/0"
}

variable "instance_type" {
    default = "t2.micro"
}

variable "private_key_file_path" {
    default = "~/.ssh/id_rsa"
}

variable "sspassword" {
    default = "FuckGFW!"
}

variable "cryptor_method" {
    default = "aes-256-cfb"
}

variable "auth_method" {
    default = "auth_aes128_md5"
}

variable "obfs_method" {
    default = "tls1.2_ticket_auth"
}

variable "port" {
    default = "443"
}


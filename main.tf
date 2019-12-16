variable "aws_access_key" {
    default = "aws_access_key"
}

variable "aws_secret_key" {
    default = "aws_secret_key"
}

# us-east-1 US East (N. Virginia)
# us-east-2 US East (Ohio)
# us-west-1 US West (N. California)
# us-west-2 US West (Oregon)
# ca-central-1 Canada (Central)
# eu-west-1 EU (Ireland)
# eu-central-1 EU (Frankfurt)
# eu-west-2 EU (London)
# ap-northeast-1 Asia Pacific (Tokyo)
# ap-northeast-2 Asia Pacific (Seoul)
# ap-southeast-1 Asia Pacific (Singapore)
# ap-southeast-2 Asia Pacific (Sydney)
# ap-south-1 Asia Pacific (Mumbai)
# sa-east-1 South America (São Paulo)
variable "region" {
    default = "ap-northeast-1"
}

variable "myip" {
    default = "your_public_ip/32"
}

#t2.nano
variable "instance_type" {
    default = "t2.micro"
}

variable "ami" {
    default = "ami-3bd3c45c"
}

variable "instance_key" {
    default = "ssh-rsa public_key"
}

variable "private_key_file_path" {
 #   default = "~\test.pem"
    default = "~\test.pem"
}

variable "sspassword" {
    default = "password"
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

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "default" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }
}

resource "aws_main_route_table_association" "a" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.default.id
}

resource "aws_subnet" "main" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.0.0/24"
}

resource "aws_security_group" "firewall" {
    name = "firewall"
    vpc_id = aws_vpc.main.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.myip]
    }

    ingress {
        from_port = var.port
        to_port = var.port
        protocol = "tcp"
        cidr_blocks = [var.myip]
    }    

    egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "ss" {
    key_name = "ss"
    public_key = var.instance_key
}

resource "aws_instance" "ss" {
        ami = var.ami
        instance_type = var.instance_type
        subnet_id = aws_subnet.main.id
        vpc_security_group_ids = [aws_security_group.firewall.id]
        key_name = "ss"        
}

resource "aws_eip" ssip {
    instance = aws_instance.ss.id
    vpc = true
}

resource "null_resource" "init_ec2" {
    depends_on = [aws_instance.ss.id]
    connection {
                user = "ec2-user"
                private_key = file(var.private_key_file_path)
                host = aws_eip.ssip.public_ip
                type = "ssh"
            }
    provisioner "remote-exec" {
        inline = [
            "sudo yum install -y git",
            "sudo git clone https://github.com/shadowsocksr-backup/shadowsocksr.git",
            "cd ~/shadowsocksr",
            "sudo git checkout manyuser",
            "sudo bash initcfg.sh",
            "sudo sed -i -e '$asudo python /home/ec2-user/shadowsocksr/shadowsocks/server.py -p ${var.port} -k ${var.sspassword} -m ${var.cryptor_method} -O ${var.auth_method} -o ${var.obfs_method} -d start' /etc/rc.d/rc.local",
            "sudo python shadowsocks/server.py -p ${var.port} -k ${var.sspassword} -m ${var.cryptor_method} -O ${var.auth_method} -o ${var.obfs_method} -d start"
        ]
    }
}

output "address" {
    value = aws_eip.ssip.public_ip
}


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
    key_name = "master"
    public_key = file("~/.ssh/master.pub")
}

resource "aws_instance" "ss" {
        ami = var.ami
        instance_type = var.instance_type
        subnet_id = aws_subnet.main.id
        vpc_security_group_ids = [aws_security_group.firewall.id]
        key_name = "master"
}

resource "aws_eip" "ssip" {
    instance = aws_instance.ss.id
    vpc = true
}

resource "null_resource" "init_ec2" {
    depends_on = [aws_instance.ss]
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
            "sudo sed -i -e '$asudo python /home/ec2-user/shadowsocksr/shadowsocks/server.py -p ${var.port} -k ${var.sspassword} -m ${var.cryptor_method} -d start' /etc/rc.d/rc.local",
            "sudo python shadowsocks/server.py -p ${var.port} -k ${var.sspassword} -m ${var.cryptor_method} -d start"
        ]
    }
}

output "address" {
    value = aws_eip.ssip.public_ip
}

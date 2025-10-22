provider "aws" {
  // Usando us-east-1 como você alterou
  region = "us-east-1" 
}

// ===================================
// SEÇÃO DE REDE COMPLETA E CORRIGIDA
// ===================================

// Cria a rede principal (VPC)
resource "aws_vpc" "lab_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Lab-VPC-Simples"
  }
}

// NOVO: O "Portão" para a Internet
resource "aws_internet_gateway" "lab_igw" {
  vpc_id = aws_vpc.lab_vpc.id
  tags = {
    Name = "Lab-IGW"
  }
}

// NOVO: O "GPS" que aponta para o portão
resource "aws_route_table" "lab_rt" {
  vpc_id = aws_vpc.lab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab_igw.id
  }

  tags = {
    Name = "Lab-Route-Table"
  }
}

// Cria uma sub-rede pública dentro da VPC
resource "aws_subnet" "lab_subnet" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "Lab-Subnet-Simples"
  }
}

// NOVO: Conecta o "GPS" à nossa sub-rede
resource "aws_route_table_association" "lab_assoc" {
  subnet_id      = aws_subnet.lab_subnet.id
  route_table_id = aws_route_table.lab_rt.id
}

// ===================================

// Grupo de Segurança: sem alterações
resource "aws_security_group" "web_sg" {
  name   = "web-server-sg-ansible"
  vpc_id = aws_vpc.lab_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// REGRA DE ENTRADA (INBOUND) PARA HTTP
resource "network_acl_id = aws_vpc.lab_vpc.default_network_acl_id" {
  network_acl_id = data.aws_network_acl.default.id
  rule_number    = 100
  egress         = false // false = Inbound
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

// REGRA DE ENTRADA (INBOUND) PARA SSH
resource "network_acl_id = aws_vpc.lab_vpc.default_network_acl_id" {
  network_acl_id = data.aws_network_acl.default.id
  rule_number    = 101 // Número de regra diferente
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

// REGRA DE SAÍDA (OUTBOUND) PARA TODO O TRÁFEGO
// Permite que o servidor responda às requisições em portas altas (efêmeras)
resource "aws_network_acl_rule" "outbound_all" {
  network_acl_id = data.aws_network_acl.default.id
  rule_number    = 100
  egress         = true // true = Outbound
  protocol       = "all" // Permite todo o protocolo
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
// A Máquina Virtual (EC2)
resource "aws_instance" "web_server" {
  ami           = "ami-0341d95f75f311023" // Cole sua AMI correta aqui
  instance_type = "t2.micro"
  key_name      = "ansible-lab-key"
  subnet_id     = aws_subnet.lab_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "WebServer-Ansible-Lab"
  }
}

// Output para nos mostrar o IP público da máquina
output "public_ip" {
  value = aws_instance.web_server.public_ip
}
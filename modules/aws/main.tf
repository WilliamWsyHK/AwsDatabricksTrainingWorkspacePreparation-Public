data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "region-name"
    values = [
      var.aws_region
    ]
  }
}

resource "aws_vpc" "databricks" {
  cidr_block           = var.databricks_vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "Name": "Databricks VPC"
  }
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.databricks.id
  cidr_block        = cidrsubnet(var.databricks_vpc_cidr, 2, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    "Name": "Databricks Private Subnet ${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_subnet" "public" {
  count = 2

  vpc_id            = aws_vpc.databricks.id
  cidr_block        = cidrsubnet(var.databricks_vpc_cidr, 2, 2+count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    "Name": "Databricks Public Subnet ${data.aws_availability_zones.available.names[count.index]}"
  }
}

resource "aws_eip" "nat_gateway" {
  domain = "vpc"

  tags = {
    "Name": "Databricks NAT Gateway Elastic IP Address"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id     = aws_eip.nat_gateway.allocation_id
  subnet_id         = aws_subnet.public[0].id
  connectivity_type = "public"

  tags = {
    "Name": "Databricks VPC NAT Gateway"
  }
}

resource "aws_internet_gateway" "this" {
  tags = {
    "Name": "Databricks VPC Internet Gateway"
  }
}

resource "aws_internet_gateway_attachment" "databricks" {
  vpc_id              = aws_vpc.databricks.id
  internet_gateway_id = aws_internet_gateway.this.id
}

resource "aws_route_table" "nat" {
  vpc_id = aws_vpc.databricks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this.id
  }

  depends_on = [
    aws_nat_gateway.this
  ]

  tags = {
    "Name": "Databricks Private Subnet Route Table"
  }
}

resource "aws_route_table" "internet" {
  vpc_id = aws_vpc.databricks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  depends_on = [
    aws_internet_gateway_attachment.databricks
  ]

  tags = {
    "Name": "Databricks Public Subnet Route Table"
  }
}

resource "aws_route_table_association" "private" {
  for_each = {
    for subnet in aws_subnet.private : subnet.availability_zone => subnet
  }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.nat.id
}

resource "aws_route_table_association" "internet" {
  for_each = {
    for subnet in aws_subnet.public : subnet.availability_zone => subnet
  }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.internet.id
}

resource "aws_network_acl" "default" {
  vpc_id = aws_vpc.databricks.id

  tags = {
    "Name": "Databricks Default Network ACL"
  }
}

resource "aws_network_acl_rule" "allow_internal_traffic_egress" {
  network_acl_id = aws_network_acl.default.id

  egress      = true
  rule_number = 1
  protocol    = "-1"
  cidr_block  = aws_vpc.databricks.cidr_block
  rule_action = "allow"
}

resource "aws_network_acl_rule" "allow_internet_tcp_http_egress" {
  network_acl_id = aws_network_acl.default.id

  egress      = true
  rule_number = 100
  protocol    = "tcp"
  cidr_block  = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  rule_action = "allow"
}

resource "aws_network_acl_rule" "allow_internet_tcp_https_egress" {
  network_acl_id = aws_network_acl.default.id

  egress      = true
  rule_number = 101
  protocol    = "tcp"
  cidr_block  = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  rule_action = "allow"
}

resource "aws_network_acl_rule" "allow_databricks_metastore_egress" {
  network_acl_id = aws_network_acl.default.id

  egress      = true
  rule_number = 102
  protocol    = "tcp"
  cidr_block  = "0.0.0.0/0"
  from_port   = 3306
  to_port     = 3306
  rule_action = "allow"
}

resource "aws_network_acl_rule" "allow_databricks_private_link_egress" {
  network_acl_id = aws_network_acl.default.id

  egress      = true
  rule_number = 103
  protocol    = "tcp"
  cidr_block  = "0.0.0.0/0"
  from_port   = 6666
  to_port     = 6666
  rule_action = "allow"
}

resource "aws_network_acl_rule" "allow_internal_traffic_ingress" {
  network_acl_id = aws_network_acl.default.id

  egress      = false
  rule_number = 1
  protocol    = "-1"
  cidr_block  = aws_vpc.databricks.cidr_block
  rule_action = "allow"
}

resource "aws_network_acl_rule" "allow_all_ingress" {
  network_acl_id = aws_network_acl.default.id

  egress      = false
  rule_number = 101
  protocol    = "-1"
  cidr_block  = "0.0.0.0/0"
  rule_action = "allow"
}

resource "aws_network_acl_association" "private" {
  for_each = {
    for subnet in aws_subnet.private : subnet.availability_zone => subnet
  }

  subnet_id      = each.value.id
  network_acl_id = aws_network_acl.default.id
}

resource "aws_network_acl_association" "public" {
  for_each = {
    for subnet in aws_subnet.public : subnet.availability_zone => subnet
  }

  subnet_id      = each.value.id
  network_acl_id = aws_network_acl.default.id
}

resource "aws_security_group" "databricks" {
  name = "Databricks-Network-Security-Group"
  description = "Allows AWS Databricks resources to communicate"
  vpc_id = aws_vpc.databricks.id

  tags = {
    "Name": "Databricks Network Security Group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_internal_traffic" {
  description                  = "Allow all incoming internal traffic within same VPC"
  security_group_id            = aws_security_group.databricks.id
  referenced_security_group_id = aws_security_group.databricks.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_internal_traffic" {
  description                  = "Allow all outgoing internal traffic within same VPC"
  security_group_id            = aws_security_group.databricks.id
  referenced_security_group_id = aws_security_group.databricks.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_internet_tcp_http" {
  description       = "Allow all Databricks outgoing HTTP traffic to Internet"
  security_group_id = aws_security_group.databricks.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_internet_tcp_https" {
  description       = "Allow all Databricks outgoing HTTPS traffic to Internet"
  security_group_id = aws_security_group.databricks.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_databricks_tcp_fips_encryption" {
  description       = "Allow all Databricks outgoing TCP traffic to support FIPS encryption"
  security_group_id = aws_security_group.databricks.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 2443  # FIPS encryption
  to_port           = 2443  # FIPS encryption
}

resource "aws_vpc_security_group_egress_rule" "allow_all_databricks_tcp_metastore" {
  description       = "Allow all Databricks outgoing TCP traffic to Databricks Metastore"
  security_group_id = aws_security_group.databricks.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 3306  # FIPS encryption
  to_port           = 3306  # FIPS encryption
}

resource "aws_vpc_security_group_egress_rule" "allow_all_databricks_tcp_secure_cluster_connectivity" {
  description       = "Allow all Databricks outgoing TCP traffic for Secure Cluster Connectivity"
  security_group_id = aws_security_group.databricks.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 6666  # Secure Cluster Connectivity
  to_port           = 6666  # Secure Cluster Connectivity
}

resource "aws_vpc_security_group_egress_rule" "allow_all_databricks_tcp_extended" {
  description       = "Allow all Databricks outgoing TCP traffic for Future extendability"
  security_group_id = aws_security_group.databricks.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 8443  # Future extendability
  to_port           = 8451  # Future extendability
}
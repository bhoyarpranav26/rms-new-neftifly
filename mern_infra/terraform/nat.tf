// NAT gateway to allow private subnets to reach the internet (eg. to call SendGrid or pull images)
// NOTE: NAT gateways incur hourly and data transfer costs. For HA across AZs create one NAT per AZ.

// Create one EIP and NAT gateway per public subnet (HA across AZs)
resource "aws_eip" "nat" {
  count = length(aws_subnet.public)
  tags = {
    Name = "${var.project_name}-nat-eip-${count.index}"
  }
}

resource "aws_nat_gateway" "nat" {
  count         = length(aws_subnet.public)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = {
    Name = "${var.project_name}-nat-${count.index}"
  }

  depends_on = [aws_internet_gateway.igw]
}

// Create a private route table per private subnet and point it to the NAT in the same index
resource "aws_route_table" "private" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${count.index}"
  }
}

// Associate each private subnet with its corresponding private route table
resource "aws_route_table_association" "private_assoc" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

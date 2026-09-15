output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "IPv4 CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs ordered like availability_zones."
  value       = [for availability_zone in var.availability_zones : aws_subnet.public[availability_zone].id]
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs ordered like availability_zones."
  value       = [for availability_zone in var.availability_zones : aws_subnet.private_app[availability_zone].id]
}

output "private_data_subnet_ids" {
  description = "Isolated private data subnet IDs ordered like availability_zones."
  value       = [for availability_zone in var.availability_zones : aws_subnet.private_data[availability_zone].id]
}

output "nat_gateway_id" {
  description = "ID of the shared NAT Gateway."
  value       = aws_nat_gateway.this.id
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.public.id
}

output "private_app_route_table_id" {
  description = "ID of the private application route table."
  value       = aws_route_table.private_app.id
}

output "private_data_route_table_id" {
  description = "ID of the isolated private data route table."
  value       = aws_route_table.private_data.id
}

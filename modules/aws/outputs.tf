output "databricks_vpc_id" {
  value = aws_vpc.databricks.id
}

output "databricks_vpc_subnet_ids" {
  value = [
    aws_subnet.private[0].id,
    aws_subnet.private[1].id
  ]
}

output "databricks_vpc_security_group_ids" {
  value = [
    aws_security_group.databricks.id
  ]
}
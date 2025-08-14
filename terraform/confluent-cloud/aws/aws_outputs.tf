output "aws_java_producer_client_id" {
  value     = aws_iam_access_key.data_contracts_bytetoeat_java_producer.id
  sensitive = true
}
output "aws_java_producer_client_secret" {
  value     = aws_iam_access_key.data_contracts_bytetoeat_java_producer.secret
  sensitive = true
}
output "aws_java_consumer_client_id" {
  value     = aws_iam_access_key.data_contracts_bytetoeat_java_consumer.id
  sensitive = true
}
output "aws_java_consumer_client_secret" {
  value     = aws_iam_access_key.data_contracts_bytetoeat_java_consumer.secret
  sensitive = true
}

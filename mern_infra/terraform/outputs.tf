output "ecr_repo" {
  value = aws_ecr_repository.app.repository_url
}

output "alb" {
  value = var.create_alb ? aws_lb.app_alb[0].dns_name : ""
}

output "cloudfront" {
  value = var.create_cloudfront ? aws_cloudfront_distribution.cdn[0].domain_name : ""
}

output "rds" {
  value = aws_db_instance.postgres.address
}

output "rds_username" {
  value = aws_db_instance.postgres.username
}

output "rds_password" {
  # The raw generated password is now stored in Secrets Manager; expose the secret ARN instead
  value     = aws_secretsmanager_secret.db_secret.arn
  sensitive = true
}

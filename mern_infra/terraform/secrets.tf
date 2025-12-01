// Store sensitive values in AWS Secrets Manager instead of exposing them in outputs
resource "aws_secretsmanager_secret" "db_secret" {
  name = "${var.project_name}-db-password"
  description = "Database password for ${var.project_name} RDS instance"
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = random_password.db.result
}

# Optional: placeholder for other secrets (email SMTP password, JWT secret) - add similarly when available

// SendGrid API key secret (used for OTP email sending)
resource "aws_secretsmanager_secret" "email_secret" {
  name        = "${var.project_name}-email-secret"
  description = "SendGrid API key (or SMTP password) for ${var.project_name}"
}

// The actual secret value should be supplied by you (do NOT hard-code).
# For local development we can create a secret_version here using a Terraform variable
# but it's safer to set the secret value manually in the AWS Console or via AWS CLI.
resource "aws_secretsmanager_secret_version" "email_secret_version" {
  secret_id = aws_secretsmanager_secret.email_secret.id
  # Use a variable if provided; default to empty string to avoid exposing creds in code.
  secret_string = var.email_secret_value != "" ? var.email_secret_value : "{\"SENDGRID_API_KEY\":\"\"}"
}
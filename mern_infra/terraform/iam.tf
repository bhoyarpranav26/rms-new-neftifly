// IAM roles for ECS task execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

// Minimal task role (application role) - empty by default
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

# Allow ECS tasks to read secrets from Secrets Manager (needed when using task definition secrets)
resource "aws_iam_role_policy" "ecs_task_secrets_policy" {
  name = "${var.project_name}-ecs-task-secrets"
  role = aws_iam_role.ecs_task_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Effect = "Allow",
        Resource = aws_secretsmanager_secret.db_secret.arn
      }
    ]
  })
}

# Policy to allow reading the email (SendGrid) secret
resource "aws_iam_role_policy" "ecs_task_email_secrets_policy" {
  name = "${var.project_name}-ecs-task-email-secrets"
  role = aws_iam_role.ecs_task_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Effect = "Allow",
        Resource = aws_secretsmanager_secret.email_secret.arn
      }
    ]
  })
}

# Execution role also needs permission to retrieve secrets at task startup
resource "aws_iam_role_policy" "ecs_task_exec_secrets_policy" {
  name = "${var.project_name}-ecs-task-exec-secrets"
  role = aws_iam_role.ecs_task_execution.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Effect = "Allow",
        Resource = [
          aws_secretsmanager_secret.db_secret.arn,
          aws_secretsmanager_secret.email_secret.arn
        ]
      }
    ]
  })
}

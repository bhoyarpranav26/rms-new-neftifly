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

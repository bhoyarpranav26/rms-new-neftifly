resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-app"
  image_tag_mutability = "MUTABLE"

  tags = {
    Name = "${var.project_name}-ecr"
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

variable "project_name" {
  type    = string
  default = "restom"
}

variable "db_username" {
  type    = string
  default = "restom_admin"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "frontend_domain" {
  type    = string
  default = ""
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "existing_vpc_id" {
  type    = string
  default = ""
  description = "If you have an existing VPC to reuse, set its ID here. Leave empty to create new networking (not implemented in Option A)."
}

variable "existing_public_subnet_id" {
  type    = string
  default = ""
  description = "ID of an existing public subnet to use for ALB/ECS."
}

variable "existing_ec2_sg_id" {
  type    = string
  default = ""
  description = "ID of an existing security group to use (eg. EC2/ALB SG)."
}

variable "frontend_bucket_name" {
  type    = string
  default = ""
  description = "Name of the existing S3 bucket used for frontend assets."
}

variable "create_alb" {
  type    = bool
  default = false
  description = "When true, create an Application Load Balancer and related resources. Set false if account doesn't support ALBs."
}

variable "create_cloudfront" {
  type    = bool
  default = false
  description = "When true, create CloudFront distribution for the frontend. Some AWS accounts require verification to create CloudFront."
}

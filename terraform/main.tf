provider "aws" {
  region = var.aws_region
}

# ------------------------------------------------------------------------------
# TERRAFORM STATE BACKEND 
# Recommendation for Idempotency: 
# Since GitHub runners are ephemeral, Terraform loses its state file on every run.
# To make this fully idempotent across multiple GitHub Action runs, you MUST
# create an S3 bucket in AWS first, then uncomment and update the block below:
# ------------------------------------------------------------------------------
terraform {
  backend "s3" {
    bucket         = "shopsmart-v2-storage-40c9dfe6"
    key            = "shopsmart/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}


# ------------------------------------------------------------------------------
# ECR REPOSITORY
# ------------------------------------------------------------------------------
resource "aws_ecr_repository" "app_repo" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ------------------------------------------------------------------------------
# EC2 Instance (Midsem Rubric: Management Server)
# ------------------------------------------------------------------------------

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "mgmt_server" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"
  
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.ecs_sg.id]
  associate_public_ip_address = true
  
  # Standard key name for AWS Academy Learner Labs
  key_name      = "vockey" 

  tags = {
    Name    = "shopsmart-mgmt-server"
    Project = var.project_name
  }
}

output "mgmt_server_public_ip" {
  description = "Public IP of the management server"
  value       = aws_instance.mgmt_server.public_ip
}

# ------------------------------------------------------------------------------
# ECS CLUSTER
# ------------------------------------------------------------------------------
resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.project_name}-cluster"
}

# ------------------------------------------------------------------------------
# IAM ROLES (Using existing LabRole provided by AWS Learner Lab)
# ------------------------------------------------------------------------------
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# ------------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 30
}

# ------------------------------------------------------------------------------
# ECS TASK DEFINITION
# ------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "app_task" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.lab_role.arn

  # We use the ECR repository URL, but with a 'latest' tag. 
  # For the very first terraform apply, if the image isn't pushed to ECR yet, 
  # ECS will fail to pull the image and the tasks will fail to start.
  # The GitHub pipeline will build the image, push it to ECR, and update the service.
  # To avoid the initial terraform apply failure, we can use a dummy image like nginx 
  # OR we can assume GitHub actions pushes the image before updating the service.
  # For pure automation, it's common to use a public placeholder image initially.
  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-container"
      image     = "${aws_ecr_repository.app_repo.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ------------------------------------------------------------------------------
# NETWORKING (Using Default VPC for simplicity)
# ------------------------------------------------------------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-ecs-sg"
  description = "Allow inbound traffic on app port"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------------------------------------------------------
# ECS SERVICE
# ------------------------------------------------------------------------------
resource "aws_ecs_service" "app_service" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

# ------------------------------------------------------------------------------
# S3 BUCKET (Required by Rubric)
# ------------------------------------------------------------------------------
resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "app_storage" {
  bucket        = "shopsmart-v2-storage-40c9dfe6"
  force_destroy = true

  tags = {
    Name    = "${var.project_name}-storage"
    Project = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "storage_versioning" {
  bucket = aws_s3_bucket.app_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "storage_encryption" {
  bucket = aws_s3_bucket.app_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "storage_public_access" {
  bucket = aws_s3_bucket.app_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

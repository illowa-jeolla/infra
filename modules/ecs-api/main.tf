data "aws_partition" "current" {}

data "aws_iam_policy_document" "task_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = merge(var.tags, {
    Name = var.cluster_name
  })
}

resource "aws_iam_role" "execution" {
  name               = var.execution_role_name
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json

  tags = merge(var.tags, {
    Name = var.execution_role_name
  })
}

resource "aws_iam_role_policy_attachment" "execution_base" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "execution_secrets" {
  role       = aws_iam_role.execution.name
  policy_arn = var.execution_secret_policy_arn
}

resource "aws_iam_role" "task" {
  name               = var.task_role_name
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json

  tags = merge(var.tags, {
    Name = var.task_role_name
  })
}

resource "aws_iam_role_policy_attachment" "task" {
  for_each = var.task_role_policy_arns

  role       = aws_iam_role.task.name
  policy_arn = each.value
}

resource "aws_cloudwatch_log_group" "api" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = var.log_group_name
  })
}

resource "aws_ecs_task_definition" "api" {
  family                   = var.task_family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.container_image
      essential = true

      portMappings = [
        {
          name          = "http"
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        for name in sort(keys(var.environment)) : {
          name  = name
          value = var.environment[name]
        }
      ]

      secrets = [
        for name in sort(keys(var.secrets)) : {
          name      = name
          valueFrom = var.secrets[name]
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.api.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = var.container_name
        }
      }

      readonlyRootFilesystem = false
      stopTimeout            = 30
    }
  ])

  tags = merge(var.tags, {
    Name = var.task_family
  })

  lifecycle {
    precondition {
      condition = var.desired_count == 0 || alltrue([
        for name in var.required_environment_names : trimspace(lookup(var.environment, name, "")) != ""
      ])
      error_message = "All required plain-text environment variables must be configured before desired_count can exceed zero."
    }

    precondition {
      condition = var.desired_count == 0 || alltrue([
        for name in var.required_secret_names : trimspace(lookup(var.secrets, name, "")) != ""
      ])
      error_message = "All required SSM secret ARNs must be configured before desired_count can exceed zero."
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.execution_base,
    aws_iam_role_policy_attachment.execution_secrets,
    aws_iam_role_policy_attachment.task,
  ]
}

resource "aws_ecs_service" "api" {
  name             = var.service_name
  cluster          = aws_ecs_cluster.this.id
  task_definition  = aws_ecs_task_definition.api.arn
  desired_count    = var.desired_count
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  enable_ecs_managed_tags            = true
  propagate_tags                     = "SERVICE"
  wait_for_steady_state              = true

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  tags = merge(var.tags, {
    Name = var.service_name
  })

  lifecycle {
    ignore_changes = [task_definition]
  }
}

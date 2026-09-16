locals {
  github_oidc_url = "https://token.actions.githubusercontent.com"
  github_subject  = "repo:${var.github_repository}:ref:${var.github_ref}"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = local.github_oidc_url

  client_id_list = [
    "sts.amazonaws.com",
  ]

  tags = merge(var.tags, {
    Name = "github-actions-oidc"
  })
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_subject]
    }
  }
}

resource "aws_iam_role" "backend_deploy" {
  name                 = var.role_name
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  max_session_duration = 3600

  tags = merge(var.tags, {
    Name = var.role_name
  })
}

data "aws_iam_policy_document" "backend_deploy" {
  statement {
    sid       = "GetEcrAuthorizationToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushBackendImage"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [var.ecr_repository_arn]
  }

  statement {
    sid    = "ReadAndRegisterTaskDefinition"
    effect = "Allow"
    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DeployBackendService"
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService",
    ]
    resources = [var.ecs_service_arn]
  }

  statement {
    sid     = "PassEcsTaskRoles"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      var.ecs_execution_role_arn,
      var.ecs_task_role_arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "backend_deploy" {
  name   = var.policy_name
  policy = data.aws_iam_policy_document.backend_deploy.json

  tags = merge(var.tags, {
    Name = var.policy_name
  })
}

resource "aws_iam_role_policy_attachment" "backend_deploy" {
  role       = aws_iam_role.backend_deploy.name
  policy_arn = aws_iam_policy.backend_deploy.arn
}

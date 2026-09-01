# Infra

AWS infrastructure planning and Terraform IaC workspace for the illowa-jeolla project.

## Purpose

This repository manages the AWS infrastructure separately from the FE and BE application repositories.

Target deployment structure:

```text
FE: React/Vite static build -> S3 + CloudFront
BE: Spring Boot Docker image -> ECR -> ECS Fargate
DB: PostgreSQL -> RDS
Cache/Token State: Redis -> ElastiCache
Ingress: ALB
Secrets: Secrets Manager or SSM Parameter Store
Logs: CloudWatch
IaC: Terraform HCL
```

## Documents

- `docs/AWS_DEPLOYMENT_STRATEGY.md`: final AWS deployment strategy
- `docs/aws-kiro.md`: Kiro steering/hook strategy for Terraform IaC work

## Planned Structure

```text
infra
├── README.md
├── docs
├── bootstrap
│   └── remote-state
├── environments
│   ├── dev
│   └── prod
├── modules
│   ├── network
│   ├── s3-cloudfront
│   ├── ecr
│   ├── alb
│   ├── ecs
│   ├── rds
│   ├── redis
│   ├── secrets
│   └── iam-github-oidc
└── .kiro
    ├── steering
    └── hooks
```

## Rules

- Do not commit Terraform state files.
- Do not commit real `.tfvars` files.
- Do not store secrets in Terraform code, Markdown docs, or examples.
- Use `terraform.tfvars.example` only for non-secret sample values.
- Run `terraform fmt` and `terraform validate` before applying infrastructure changes.
- Review `terraform plan` before every apply.

Initial infrastructure apply should be manual, not automatically triggered by merge.

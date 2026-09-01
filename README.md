# Infra

illowa-jeolla 프로젝트의 AWS 인프라 설계 문서와 Terraform IaC를 관리하는 저장소입니다.

## 목적

이 저장소는 FE/BE 애플리케이션 코드와 AWS 인프라 코드를 분리해서 관리하기 위한 공간입니다.

최종 배포 구조는 아래 방향을 기준으로 합니다.

```text
FE: React/Vite 정적 빌드 -> S3 + CloudFront
BE: Spring Boot Docker image -> ECR -> ECS Fargate
DB: PostgreSQL -> RDS
Cache/Token State: Redis -> ElastiCache
Ingress: ALB
Secret: Secrets Manager 또는 SSM Parameter Store
Logs: CloudWatch
IaC: Terraform HCL
```

## 문서

- `docs/AWS_DEPLOYMENT_STRATEGY.md`: 최종 AWS 배포 전략
- `docs/aws-kiro.md`: Kiro steering/hook을 활용한 Terraform IaC 작성 및 검증 전략

## 예정 구조

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

## 기본 규칙

- Terraform state 파일은 커밋하지 않습니다.
- 실제 값이 들어간 `.tfvars` 파일은 커밋하지 않습니다.
- Terraform 코드, Markdown 문서, 예시 파일에 secret 값을 저장하지 않습니다.
- `terraform.tfvars.example`에는 민감하지 않은 샘플 값만 작성합니다.
- 인프라 변경 전 `terraform fmt`와 `terraform validate`를 실행합니다.
- `terraform apply` 전에는 항상 `terraform plan` 결과를 검토합니다.

초기 인프라 반영은 merge 자동 실행이 아니라 수동 실행을 기준으로 합니다.

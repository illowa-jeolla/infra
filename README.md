# Infra

illowa-jeolla 프로젝트의 AWS 인프라 설계 문서와 Terraform IaC를 관리하는 저장소입니다.

## 목적

이 저장소는 BE 애플리케이션의 AWS 인프라와 Terraform state 기반을 관리하기 위한 공간입니다. FE React/Vite 앱은 Vercel에서 별도로 배포합니다.

최종 배포 구조는 아래 방향을 기준으로 합니다.

```text
FE: React/Vite -> Vercel (AWS 관리 범위 밖)
BE: Spring Boot Docker image -> ECR -> ECS Fargate
DB: PostgreSQL -> RDS
Cache/Token State: Redis -> ElastiCache
Ingress: ALB
Asset: Community image -> private S3
Secret: SSM Parameter Store
Logs: CloudWatch
IaC: Terraform HCL
```

## 문서

- `docs/AWS_DEPLOYMENT_STRATEGY.md`: 최종 AWS 배포 전략
- `docs/aws-kiro.md`: Kiro steering/hook을 활용한 Terraform IaC 작성 및 검증 전략
- `docs/DEPLOYMENT_CONTRACT.md`: Vercel FE와 AWS BE 사이의 배포 계약
- `docs/RESOURCE_NAMING.md`: AWS 리소스 이름과 태그 기준
- `docs/aws_log.md`: 결정 및 작업 이력

## 구조

```text
infra
├── README.md
├── docs
├── bootstrap
│   └── remote-state
├── environments
│   └── main
├── modules
│   ├── network
│   ├── security-groups
│   ├── s3-assets
│   ├── ecr
│   ├── alb
│   ├── ecs-api
│   ├── rds
│   ├── redis
│   ├── secrets
│   └── github-oidc
└── docs
```

S3는 Terraform remote state와 커뮤니티 이미지 저장에만 사용합니다. FE 정적 호스팅용 S3와 CloudFront는 만들지 않습니다.

## 기본 규칙

- Terraform state 파일은 커밋하지 않습니다.
- 실제 값이 들어간 `.tfvars` 파일은 커밋하지 않습니다.
- Terraform 코드, Markdown 문서, 예시 파일에 secret 값을 저장하지 않습니다.
- main 환경은 secret의 write-only/ephemeral 처리를 위해 Terraform 1.11 이상을 사용합니다.
- `terraform.tfvars.example`에는 민감하지 않은 샘플 값만 작성합니다.
- 인프라 변경 전 `terraform fmt`와 `terraform validate`를 실행합니다.
- `terraform apply` 전에는 항상 `terraform plan` 결과를 검토합니다.

초기 인프라 반영은 merge 자동 실행이 아니라 수동 실행을 기준으로 합니다.

## Main 환경 검증

최초 초기화 시 bootstrap으로 생성한 state bucket 이름을 전달합니다.

```bash
cd environments/main
terraform init -reconfigure \
  -backend-config="bucket=illowa-jeolla-tfstate-862138198898"
terraform fmt -check -recursive ../..
terraform validate
terraform plan
```

현재 main 환경에는 Network, ECR, Security Group, 커뮤니티 이미지 S3, RDS, Redis, DB/Redis 비밀번호용 SSM Parameter Store와 읽기 IAM 정책이 적용돼 있습니다. 이후 인프라 변경도 `terraform plan` 검토와 명시적 승인 후 적용합니다.

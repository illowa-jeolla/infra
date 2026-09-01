# AWS IaC with Kiro

## 목적

AWS 인프라는 별도 infra 레포에서 Terraform HCL로 관리한다.

Kiro는 인프라를 직접 생성하는 도구가 아니라, Terraform IaC 작성과 사전 검증을 돕는 보조 도구로 사용한다. 실제 AWS 리소스 생성, 수정, 삭제는 Terraform과 GitHub Actions를 통해 수행한다.

## 역할 구분

```text
Kiro Steering
-> IaC 작성 규칙과 프로젝트 원칙을 제공

Kiro Hook
-> IaC 작성 중 자동 포맷, 검증, 위험 명령 경고를 수행

Terraform
-> 실제 AWS 리소스 생성, 수정, 삭제를 수행

GitHub Actions
-> PR/main 기준 공식 검증과 Terraform plan/apply 자동화를 수행
```

즉 Kiro는 작성 보조와 로컬/에이전트 레벨 검증을 담당하고, GitHub Actions는 merge 전후의 공식 검증과 실행을 담당한다.

## 전체 흐름

```text
1. infra repo 생성
2. .kiro/steering 작성
3. .kiro/hooks 작성
4. Kiro가 steering file을 참고해서 Terraform HCL 작성
5. Kiro hook이 저장/작업 종료 시 fmt, validate, 위험 명령 체크
6. 사람이 코드 리뷰
7. GitHub PR 생성
8. GitHub Actions가 terraform fmt -check, validate, plan 실행
9. plan 결과 확인
10. main merge
11. GitHub Actions에서 terraform apply 실행
12. AWS 리소스 생성
13. FE/BE main CI/CD가 생성된 AWS 리소스에 앱 배포
```

초기에는 `terraform apply`를 main merge에 바로 자동 연결하지 않고, `workflow_dispatch` 수동 실행으로 둔다. 인프라 변경은 앱 배포보다 영향 범위가 크기 때문이다.

## Infra Repository 구조

```text
infra
├── README.md
├── environments
│   ├── dev
│   │   ├── main.tf
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   └── prod
│       ├── main.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
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
├── .kiro
│   ├── steering
│   └── hooks
└── .github
    └── workflows
        └── terraform.yml
```

## Steering File 전략

Steering file은 Kiro가 Terraform 코드를 작성할 때 참고하는 프로젝트 규칙이다.

```text
infra
└── .kiro
    └── steering
        ├── product.md
        ├── tech.md
        ├── structure.md
        ├── terraform-standards.md
        ├── aws-security.md
        └── deployment-workflow.md
```

각 파일 역할:

- `product.md`: FE/BE/infra 레포 분리, 최종 배포 목적, 서비스 구조
- `tech.md`: Terraform HCL only, AWS provider, ap-northeast-2, ECS Fargate 기준
- `structure.md`: environments와 modules 디렉터리 구조
- `terraform-standards.md`: naming convention, variable/output 규칙, remote state, module 작성 규칙
- `aws-security.md`: public RDS/Redis 금지, ALB만 public, least privilege IAM, security group 규칙
- `deployment-workflow.md`: infra PR plan, main apply, FE/BE 앱 배포와 infra apply 분리

권장 inclusion:

```text
always:
- product.md
- tech.md
- structure.md
- aws-security.md

fileMatch:
- terraform-standards.md

manual:
- deployment-workflow.md
- production-checklist.md
```

Steering file에는 실제 secret 값을 넣지 않는다. 규칙, 리소스 이름 예시, 보안 원칙만 작성한다.

## Redis / ElastiCache 작성 규칙

Kiro가 Redis 관련 Terraform을 작성할 때는 ElastiCache를 private cache subnet에 배치하는 구성을 기본값으로 둔다. Redis는 public subnet에 만들지 않고, Security Group inbound는 ECS Task Security Group에서 오는 `6379`만 허용한다.

초기 module은 비용 절감형과 운영 안정형을 모두 표현할 수 있게 작성한다.

```text
초기 비용 절감형:
- ElastiCache Redis single node
- Multi-AZ disabled
- automatic failover disabled
- snapshot retention 1~3일

운영 안정형:
- ElastiCache Redis replication group
- primary 1개 + replica 1개 이상
- Multi-AZ enabled
- automatic failover enabled
- snapshot retention 3~7일
```

Terraform module 입력값은 아래 항목을 포함한다.

```text
name_prefix
vpc_id
subnet_ids
allowed_sg_ids
engine_version
node_type
mode
replicas_per_node_group
automatic_failover_enabled
multi_az_enabled
at_rest_encryption_enabled
transit_encryption_enabled
auth_token_enabled
snapshot_retention_limit
```

보안 기본값:

- `at_rest_encryption_enabled = true`
- `transit_encryption_enabled = true`
- `auth_token_enabled = true`
- Redis AUTH token을 Terraform 코드와 tfvars에 평문으로 작성하지 않는다.
- AUTH token은 Secrets Manager 또는 SSM Parameter Store에 저장하고 ECS Task Definition에서 secret으로 주입한다.
- Redis endpoint, port, SSL 여부는 BE 운영 환경변수로 주입한다.

Kiro가 Redis Terraform을 작성한 뒤 사람이 반드시 확인할 항목:

- Redis가 public subnet에 생성되지 않았는지
- Security Group이 `0.0.0.0/0`에 `6379`를 열지 않았는지
- AUTH token이 tfstate에 민감하게 남는 구조가 아닌지
- 인증/세션 저장 용도인데 single node로 운영하는 리스크를 팀이 수용했는지
- replication group 전환 시 replacement가 발생하는지
- node type과 replica 수가 예상 비용 범위 안에 있는지

## Hook 전략

Hook은 Kiro 작업 중 특정 이벤트가 발생하면 자동으로 실행되는 검사/자동화 장치다.

```text
infra
└── .kiro
    └── hooks
        ├── terraform-fmt-on-save.json
        ├── terraform-validate-on-save.json
        ├── block-dangerous-terraform.json
        └── stop-require-plan.json
```

처음부터 hook을 과하게 걸면 개발 흐름이 답답해진다. 초기에는 `terraform fmt`와 종료 전 검증 확인 정도만 자동화하고, 최종 강제 검증은 GitHub Actions에 둔다.

## Hook 예시

### Terraform 저장 시 fmt

```json
{
  "version": "v1",
  "hooks": [
    {
      "name": "Terraform fmt on save",
      "trigger": "PostFileSave",
      "matcher": "\\.(tf|tfvars)$",
      "action": {
        "type": "command",
        "command": "terraform fmt -recursive"
      }
    }
  ]
}
```

### Terraform validate

`terraform validate`는 해당 environment에서 `terraform init`이 선행되어야 한다. 따라서 무조건 전체에 걸기보다 `environments/dev` 또는 `environments/prod` 기준으로 나누는 것이 좋다.

```json
{
  "version": "v1",
  "hooks": [
    {
      "name": "Terraform validate dev",
      "trigger": "PostFileSave",
      "matcher": "^(environments/dev|modules)/.*\\.tf$",
      "action": {
        "type": "command",
        "command": "terraform -chdir=environments/dev validate"
      }
    }
  ]
}
```

### 위험한 Terraform 명령 경고

`terraform destroy`, `terraform apply -auto-approve`처럼 리소스 삭제 또는 즉시 반영 가능성이 큰 명령은 자동 실행하지 않는다.

```json
{
  "version": "v1",
  "hooks": [
    {
      "name": "Block dangerous terraform commands",
      "trigger": "PreToolUse",
      "matcher": "shell",
      "action": {
        "type": "agent",
        "prompt": "Before running terraform destroy, terraform apply -auto-approve, or any command that deletes AWS resources, stop and ask the user for explicit confirmation. Do not proceed automatically."
      }
    }
  ]
}
```

실제로 강하게 막고 싶다면 agent prompt보다 command hook으로 tool input을 검사하고 block exit를 반환하는 방식이 더 낫다.

### 작업 종료 전 검증 확인

```json
{
  "version": "v1",
  "hooks": [
    {
      "name": "Require terraform checks before stop",
      "trigger": "Stop",
      "action": {
        "type": "agent",
        "prompt": "If Terraform files were changed, confirm whether terraform fmt and terraform validate were run. If not, run or explicitly report why they were not run before finalizing."
      }
    }
  ]
}
```

## GitHub Actions 전략

Kiro hook이 통과했더라도 GitHub Actions 검증은 반드시 다시 수행한다. 로컬 환경과 CI 환경이 다를 수 있고, Terraform backend/state 권한도 CI에서 최종 확인해야 하기 때문이다.

infra PR:

```text
Pull Request to infra main
  |
  v
GitHub Actions
  |
  +--> terraform fmt -check
  +--> terraform validate
  +--> terraform plan
```

infra main:

```text
Merge to infra main
  |
  v
GitHub Actions
  |
  +--> terraform apply
```

초기에는 apply를 자동 실행하지 않고 수동 workflow로 둔다.

```text
workflow_dispatch
  |
  v
terraform apply
```

## Terraform State

Terraform state는 로컬 파일로 관리하지 않는다.

```text
Terraform state -> S3
Terraform lock  -> DynamoDB
```

S3 backend와 DynamoDB lock table을 최초로 만드는 bootstrap 단계는 별도 HCL 또는 수동 1회 작업으로 분리한다. 이후 나머지 인프라는 remote backend를 사용한다.

## Kiro 사용 원칙

Kiro에 맡겨도 되는 일:

- Terraform module 초안 생성
- variables/outputs 정리
- security group 규칙 초안 작성
- GitHub Actions workflow 초안 작성
- README와 운영 문서 초안 작성
- terraform plan 결과를 보고 수정 제안

반드시 사람이 검토해야 하는 일:

- IAM policy 권한 범위
- Security Group의 public open 여부
- RDS public accessibility
- Redis public exposure
- NAT Gateway 비용 구조
- Secrets가 tfstate에 남는지 여부
- Terraform state backend 설정
- terraform apply 결과
- 리소스 삭제 또는 교체가 발생하는 plan

## 결론

```text
Steering file = Kiro가 따라야 할 작성 규칙
Hook = Kiro 작업 중 자동으로 실행되는 검사/자동화
GitHub Actions = PR/main에서 공식 검증과 실행
Terraform = 실제 AWS 리소스를 생성, 수정, 삭제하는 도구
```

Kiro steering/hook으로 Terraform IaC 작성과 사전 검사를 보조하고, 실제 인프라 생성은 GitHub Actions에서 Terraform plan/apply로 수행한다.

apply는 초반에 자동 merge-trigger보다 수동 버튼으로 두는 것이 안전하다.

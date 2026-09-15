# Resource Naming

최종 갱신일: 2026-09-15

이 문서는 `illowa-jeolla` AWS 인프라의 리소스 이름과 공통 태그를 정의한다. 현재 Terraform 환경은 `main` 하나만 사용하며, 이 문서의 이름을 Terraform 구현의 기준으로 삼는다.

## 1. 기본 규칙

```text
project     = illowa-jeolla
environment = main
name_prefix = illowa-jeolla-main
region      = ap-northeast-2
```

- 이름은 소문자 영문, 숫자, 하이픈을 기본으로 사용한다.
- 환경에 속하는 리소스는 `illowa-jeolla-main` 접두사를 사용한다.
- AWS 서비스의 길이 제한 때문에 축약이 필요할 때만 `svc`, `tg`, `rt`, `sg`를 사용한다.
- 임의의 날짜, 담당자 이름, 브랜치 이름은 리소스 이름에 넣지 않는다.
- S3 bucket처럼 전역에서 고유해야 하는 이름에는 AWS account ID를 붙인다.
- secret 값은 이름에 포함하지 않는다.

## 2. 공통 태그

태그를 지원하는 모든 리소스에 아래 값을 적용한다.

| Key | Value |
| --- | --- |
| `Project` | `illowa-jeolla` |
| `Environment` | `main` |
| `ManagedBy` | `terraform` |
| `Repository` | `illowa-jeolla/infra` |

리소스의 표시 이름이 `Name` 태그로 결정되는 경우 아래 패턴을 사용한다.

```text
Name = illowa-jeolla-main-<resource-purpose>
```

## 3. Terraform state

| 대상 | 이름 |
| --- | --- |
| State bucket | `illowa-jeolla-tfstate-<aws-account-id>` |
| Main state key | `main/terraform.tfstate` |

`<aws-account-id>`는 bootstrap이 현재 AWS caller identity에서 자동으로 결정한다. Terraform 1.10 이상의 S3 native lockfile을 사용하므로 DynamoDB lock table은 만들지 않는다.

## 4. Network

| 리소스 | 이름 |
| --- | --- |
| VPC | `illowa-jeolla-main-vpc` |
| Internet Gateway | `illowa-jeolla-main-igw` |
| NAT Gateway | `illowa-jeolla-main-nat` |
| Public subnet A | `illowa-jeolla-main-public-a` |
| Public subnet C | `illowa-jeolla-main-public-c` |
| Private app subnet A | `illowa-jeolla-main-app-a` |
| Private app subnet C | `illowa-jeolla-main-app-c` |
| Private data subnet A | `illowa-jeolla-main-data-a` |
| Private data subnet C | `illowa-jeolla-main-data-c` |
| Public route table | `illowa-jeolla-main-public-rt` |
| Private app route table | `illowa-jeolla-main-app-rt` |
| Private data route table | `illowa-jeolla-main-data-rt` |

`a`, `c`는 기본 AZ 구분자다. 실제 Terraform에서는 선택한 AZ 목록의 순서와 subnet 이름이 일치해야 한다.

초기 네트워크 CIDR은 다음 값을 사용한다.

| 구분 | A (`ap-northeast-2a`) | C (`ap-northeast-2c`) |
| --- | --- | --- |
| Public | `10.0.0.0/24` | `10.0.1.0/24` |
| Private app | `10.0.10.0/24` | `10.0.11.0/24` |
| Private data | `10.0.20.0/24` | `10.0.21.0/24` |

VPC CIDR은 `10.0.0.0/16`이다. Private app subnet은 단일 NAT Gateway를 통해 외부로 나가며, Private data subnet에는 인터넷 기본 경로를 만들지 않는다.

## 5. Security groups

| 대상 | 이름 |
| --- | --- |
| ALB | `illowa-jeolla-main-alb-sg` |
| ECS API | `illowa-jeolla-main-api-sg` |
| RDS | `illowa-jeolla-main-rds-sg` |
| Redis | `illowa-jeolla-main-redis-sg` |

Security group rule의 `description`에는 허용 주체와 포트를 함께 적는다. 예: `Allow API tasks to PostgreSQL 5432`.

Security group은 `modules/security-groups`에서 함께 생성해 ALB, ECS, RDS, Redis 모듈 사이의 순환 의존성을 방지한다.

## 6. Container and load balancing

| 리소스 | 이름 |
| --- | --- |
| ECR repository | `illowa-jeolla-main-api` |
| ECS cluster | `illowa-jeolla-main-cluster` |
| ECS service | `illowa-jeolla-main-api-svc` |
| ECS task definition family | `illowa-jeolla-main-api` |
| Container | `api` |
| Application Load Balancer | `illowa-jeolla-main-alb` |
| Target group | `illowa-jeolla-main-api-tg` |

별도 Batch Worker ECS Service와 SQS/DLQ는 만들지 않는다. API의 초기 desired count는 1이다.

CloudWatch log group:

```text
/ecs/illowa-jeolla/main/api
```

## 7. Data

| 리소스 | 이름 |
| --- | --- |
| RDS instance identifier | `illowa-jeolla-main-db` |
| RDS subnet group | `illowa-jeolla-main-db-subnets` |
| RDS parameter group | `illowa-jeolla-main-postgres` |
| PostgreSQL database | `illowajeolla` |
| ElastiCache identifier | `illowa-jeolla-main-redis` |
| ElastiCache subnet group | `illowa-jeolla-main-redis-subnets` |
| ElastiCache parameter group | `illowa-jeolla-main-redis` |

PostgreSQL database 이름은 하이픈 없이 `illowajeolla`를 사용한다. DB 사용자 이름과 비밀번호는 리소스 이름 문서에서 고정하지 않고 secret으로 관리한다.

## 8. S3 assets

| 대상 | 이름 |
| --- | --- |
| Community image bucket | `illowa-jeolla-main-assets-<aws-account-id>` |
| API asset access policy | `illowa-jeolla-main-assets-access-policy` |

S3 bucket의 `<aws-account-id>`는 실제 12자리 AWS account ID로 치환한다. Community image bucket은 `modules/s3-assets`에서 생성한다. FE는 Vercel에서 배포하므로 FE bucket, CloudFront distribution, OAC는 만들지 않는다.

## 9. SSM Parameter Store

Parameter 경로 접두사:

```text
/illowa-jeolla/main/
```

민감값은 SecureString으로 저장한다.

```text
/illowa-jeolla/main/db/password
/illowa-jeolla/main/redis/password
/illowa-jeolla/main/jwt/secret
/illowa-jeolla/main/oauth/kakao/client-secret
/illowa-jeolla/main/oauth/google/client-secret
/illowa-jeolla/main/api/kakao-map-key
/illowa-jeolla/main/api/tour-info-key
/illowa-jeolla/main/api/tour-job-key
/illowa-jeolla/main/api/junnam-job-key
/illowa-jeolla/main/api/openai-key
```

endpoint, port처럼 Terraform output으로 ECS에 직접 전달할 수 있는 값은 Parameter Store에 중복 저장하지 않는다.

## 10. IAM and GitHub OIDC

| 역할 | 이름 |
| --- | --- |
| ECS task execution role | `illowa-jeolla-main-ecs-execution-role` |
| ECS API task role | `illowa-jeolla-main-api-task-role` |
| BE deploy role | `illowa-jeolla-main-be-deploy-role` |
| Terraform plan role | `illowa-jeolla-main-tf-plan-role` |
| Terraform apply role | `illowa-jeolla-main-tf-apply-role` |

AWS account 단위 GitHub OIDC provider는 중복 생성하지 않는다. IAM trust policy는 AWS에 배포하는 `illowa-jeolla/BE`와 `illowa-jeolla/infra`의 필요한 브랜치와 workflow만 허용한다. FE의 Vercel 배포에는 AWS IAM role을 부여하지 않는다.

## 11. 최종 이름 요약

```text
illowa-jeolla-main-vpc
illowa-jeolla-main-api
illowa-jeolla-main-cluster
illowa-jeolla-main-api-svc
illowa-jeolla-main-alb
illowa-jeolla-main-api-tg
illowa-jeolla-main-db
illowa-jeolla-main-redis
illowa-jeolla-main-assets-<aws-account-id>
/ecs/illowa-jeolla/main/api
/illowa-jeolla/main/
```

리소스 구현 시 서비스별 제약으로 이름을 변경해야 한다면 이 문서를 먼저 수정한 뒤 Terraform에 반영한다.

# AWS Deployment Strategy: ECS 기반 최종 배포 구조

## 현재 팀 상황

- BE는 Spring Boot 기반 API 서버다.
- BE 로컬 개발은 Docker Compose로 PostgreSQL, Redis를 띄우고 Spring Boot를 실행한다.
- FE는 React/Vite 앱으로 전환 중이다.
- FE 저장소에는 전환용 Node.js API 서버와 SQLite DB가 함께 있지만, 운영 백엔드로 사용하지 않는다.
- FE 팀은 BE가 작성한 API 명세를 기준으로 React 앱의 API 호출을 맞춘다.
- 작업은 feature 브랜치에서 진행하고, PR을 통해 develop으로 merge한다.
- develop에서는 FE/BE 통합 개발 테스트를 진행한다.
- 통합 테스트가 완료되면 main으로 merge한다.
- FE main은 Vercel 배포, BE main은 AWS ECS 배포 트리거로 사용한다.
- AWS 인프라는 별도 infra 레포에서 Terraform HCL로 관리한다.

## 결론

최종 배포 구조는 ECS Fargate를 기준으로 잡는다.

EKS는 Kubernetes 운영 경험을 얻을 수 있지만, 현재 팀 상황에서는 배포 기반을 만드는 데 필요한 운영 복잡도가 크다. 이번 프로젝트의 우선순위는 FE/BE를 안정적으로 분리 배포하고, main 브랜치 기준으로 자동 배포되는 구조를 만드는 것이다.

따라서 최종 구조는 다음을 목표로 한다. AWS Terraform의 범위는 BE와 데이터 계층이며 FE hosting은 Vercel이 담당한다.

```text
FE: React/Vite -> Vercel
BE: Spring Boot Docker Image -> ECR -> ECS Fargate
DB: PostgreSQL -> RDS
Cache/Token State: Redis -> ElastiCache
Ingress: ALB
Asset: Community image -> private S3
Secret: SSM Parameter Store
Logs: CloudWatch
CI/CD: FE main -> Vercel, BE main -> GitHub Actions/ECS
IaC: infra repo의 Terraform HCL
```

## Repository 전략

최종 레포는 FE, BE, infra를 분리한다.

```text
illowa-jeolla/FE
├── React/Vite app
└── Vercel project configuration

illowa-jeolla/BE
├── Spring Boot app
├── Dockerfile
└── .github/workflows/deploy-be.yml

illowa-jeolla/infra
├── Terraform HCL
└── .github/workflows/terraform.yml
```

역할:

- `FE`: React 코드와 Vercel 배포 설정
- `BE`: Spring Boot 코드와 BE ECS 배포 파이프라인
- `infra`: VPC, ECS, ALB, RDS, Redis, community image S3, ECR, IAM, GitHub OIDC 등 BE용 AWS 리소스 정의

애플리케이션 배포와 인프라 변경은 분리한다. FE/BE 코드가 바뀔 때마다 Terraform apply를 실행하지 않는다.

```text
FE main push -> Vercel production 배포
BE main push -> BE 앱 배포
infra main 변경 -> AWS 인프라 plan/apply
```

## 브랜치 전략

브랜치 흐름은 다음을 기준으로 한다.

```text
feature/*
  |
  v
develop
  |
  v
main
```

각 브랜치의 역할:

- `feature/*`: 각 개발자가 기능을 구현하는 브랜치
- `develop`: 기능을 모아 FE/BE 통합 개발 테스트를 진행하는 브랜치
- `main`: 테스트가 끝난 코드를 운영 환경에 배포하는 브랜치

운영 배포는 `main` push에서만 실행한다. Git에 코드가 올라올 때마다 새 인스턴스를 만드는 방식이 아니라, 이미 준비된 AWS 리소스에 새 빌드 결과물을 반영한다.

## 현재 프로젝트 구조 판단

```text
tour_gong
├── BE
│   ├── Spring Boot
│   ├── Gradle
│   ├── docker-compose.yml
│   └── src/main/resources/application.yaml
└── FE
    └── --main/travel-workation
        ├── react-app
        │   ├── package.json
        │   ├── vite.config.js
        │   └── src
        ├── server.js
        ├── data/workation.db
        └── legacy HTML/CSS/JS files
```

현재 FE의 `server.js`는 React 빌드 파일 서빙, `/api/*` API, SQLite DB를 함께 담당한다. 이것은 운영용 최종 구조가 아니라 React 전환 과정에서 사용하는 프로토타입/목업 서버로 본다.

운영에서는 FE가 직접 DB나 Node API 서버를 들고 가지 않는다. React 앱은 정적 파일로 배포하고, 모든 서비스 데이터와 인증은 Spring Boot BE API를 통해 처리한다.

## 전체 AWS 구조

```text
Users
  |
  +--> Vercel React/Vite
  |
  +--> api.illowa-jeolla.cloud / HTTPS ALB
                         |
                         v
                   ECS Fargate API
                         |
              +----------+----------+
              |          |          |
              v          v          v
             RDS       Redis    private S3 assets
```

AWS 리소스 기준:

```text
AWS
├── Route 53
├── VPC
│   ├── Public Subnet A
│   │   ├── ALB
│   │   └── NAT Gateway
│   ├── Public Subnet B
│   │   └── ALB
│   ├── Private App Subnet A
│   │   └── ECS Fargate Task
│   ├── Private App Subnet B
│   │   └── ECS Fargate Task
│   ├── Private DB Subnet A
│   │   └── RDS PostgreSQL
│   └── Private DB Subnet B
│       └── RDS PostgreSQL Standby 또는 Subnet Group
├── ECR
│   └── Spring Boot Docker Image
├── ECS
│   ├── Cluster
│   ├── Task Definition
│   └── Service
├── RDS PostgreSQL
├── ElastiCache Redis
├── S3
│   └── Community images
├── Secrets Manager 또는 SSM Parameter Store
└── CloudWatch Logs
```

위 AWS 리소스는 모두 infra 레포의 Terraform HCL로 정의한다. AWS 콘솔에서 수동으로 만든 리소스가 생기더라도 최종 상태는 Terraform 코드와 맞춰야 한다.

## IaC 구성

IaC는 Terraform HCL만 사용한다. CloudFormation, CDK, Pulumi는 사용하지 않는다.

infra 레포 구조 초안:

```text
infra
├── README.md
├── bootstrap
│   └── remote-state
├── environments
│   └── main
│       ├── backend.tf
│       ├── main.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
├── modules
│   ├── network
│   ├── s3-assets
│   ├── ecr
│   ├── alb
│   ├── ecs-api
│   ├── rds
│   ├── redis
│   ├── secrets
│   └── github-oidc
└── .github
    └── workflows
        └── terraform.yml
```

Terraform으로 관리할 리소스:

- VPC
- Public Subnet
- Private App Subnet
- Private DB/Cache Subnet
- Internet Gateway
- NAT Gateway
- Route Table
- Security Group
- S3 bucket for community images
- ECR repository
- ALB
- Target Group
- ECS Cluster
- ECS Task Definition
- ECS Service
- ECS Auto Scaling (scheduler 분리 또는 분산 lock 적용 후 선택)
- RDS PostgreSQL
- ElastiCache Redis
- Secrets Manager 또는 SSM Parameter Store
- IAM Role
- GitHub Actions OIDC Provider/Role
- CloudWatch Log Group

Terraform state는 로컬 파일로 관리하지 않는다. S3 backend와 native lockfile을 사용한다.

```text
Terraform state -> S3
Terraform lock  -> S3 native lockfile
```

단, S3 backend bucket을 최초로 만드는 `bootstrap/remote-state`는 로컬 state로 한 번 실행한다. 이후 `environments/main`은 Terraform 1.10 이상의 `use_lockfile = true` 설정으로 remote backend를 사용한다. deprecated된 DynamoDB locking은 새로 만들지 않는다.

## ECS 구성 개념

ECS는 컨테이너 자체가 아니라 컨테이너 실행을 관리하는 서비스다.

```text
ECS Cluster
└── ECS Service
    └── Task
        └── Container
```

역할:

- `ECS Cluster`: 컨테이너 실행 환경을 묶는 논리 단위
- `ECS Service`: Task 개수를 유지하고 ALB Target Group과 연결하는 단위
- `Task Definition`: 어떤 Docker image를 어떤 CPU/Memory/env/log 설정으로 실행할지 정의하는 템플릿
- `Task`: 실행 중인 컨테이너 묶음 1개
- `Container`: 실제 Spring Boot Docker 컨테이너

이번 프로젝트에서는 ECS Fargate를 사용한다. EC2 인스턴스를 직접 관리하지 않고, Task Definition에 CPU/Memory를 지정하면 AWS가 실행 환경을 관리한다.

예시:

```text
illowa-jeolla-main-cluster
└── illowa-jeolla-main-api-svc
    └── task 1
        └── api container
```

## FE 배포 구조

FE React/Vite 앱은 Vercel project로 배포한다. FE 정적 파일을 AWS S3에 업로드하거나 CloudFront invalidation을 실행하지 않는다. Vercel project와 domain은 FE 담당 범위이며 Terraform으로 관리하지 않는다.

운영 환경변수 예시:

```text
VITE_API_BASE_URL=https://api.illowa-jeolla.cloud
VITE_KAKAO_MAP_JAVASCRIPT_KEY=...
VITE_AUTH_API_ENABLED=true
VITE_AUTH_API_ORIGIN=https://api.illowa-jeolla.cloud
VITE_AUTH_API_BASE_PATH=/api/v1
```

주의할 점:

- `FE/--main/travel-workation/server.js`는 운영 백엔드로 보지 않는다.
- `FE/--main/travel-workation/data/workation.db`는 운영 DB로 사용하지 않는다.
- FE의 기존 `/api/*` 호출은 BE API 명세 기준으로 `/api/v1/*` 또는 운영 API URL에 맞춰 정리한다.
- `VITE_API_BASE_URL`과 `VITE_AUTH_API_ORIGIN`에는 AWS BE의 HTTPS URL을 넣는다.
- Vercel production domain을 BE의 `FRONTEND_ORIGIN`과 `FRONTEND_OAUTH_CALLBACK_URI`에 반영한다.
- Vite SPA deep link를 위해 FE project root에 `vercel.json` rewrite를 둔다.
- Vercel preview URL은 기본 CORS 허용 대상에서 제외하고, 초기 배포는 고정 production domain만 연동한다.

## BE 배포 구조

BE는 Docker image로 빌드한 뒤 ECR에 push하고, ECS Fargate가 해당 image를 pull해서 실행한다.

```text
BE 코드
  |
  v
Docker build
  |
  v
Docker image
  |
  v
ECR push
  |
  v
ECS Task가 ECR image pull
  |
  v
Spring Boot container 실행
```

로컬에서 실행하던 컨테이너를 그대로 AWS에 복사하는 것이 아니다. 같은 코드로 만든 Docker image를 ECR에 올리고, 운영 환경변수는 ECS Task Definition과 Secrets Manager 또는 SSM Parameter Store로 별도 주입한다.

```text
같은 Docker image
다른 environment variables
다른 DB/Redis 연결
```

예시:

```text
로컬:
POSTGRES_HOST=localhost
REDIS_HOST=localhost
JWT_COOKIE_SECURE=false

운영:
POSTGRES_HOST=<rds-endpoint>
REDIS_HOST=<elasticache-endpoint>
JWT_COOKIE_SECURE=true
SPRING_PROFILES_ACTIVE=prod
```

## BE 로컬 개발 구조

BE 로컬 개발은 Docker Compose를 유지한다.

```text
Docker Compose
├── PostgreSQL
└── Redis

Spring Boot
└── local JVM에서 실행
```

목적:

- BE 개발자가 같은 방식으로 DB와 Redis 의존성을 실행한다.
- PR 전 API 동작을 Postman, curl, FE 개발 서버로 확인한다.
- OAuth, JWT, 관광 API, 일자리 API, 여행 추천 API를 로컬에서 검증한다.

현재 `BE/docker-compose.yml`은 PostgreSQL과 Redis만 띄운다. Spring Boot까지 Compose에 포함하는 것은 필수는 아니지만, Docker image 검증 단계에서는 별도 컨테이너 실행을 확인해야 한다.

## FE/BE API 계약 정리

운영 기준 API는 Spring Boot BE가 제공한다.

현재 BE에서 확인되는 주요 API 축:

```text
/api/v1/auth
/api/v1/auth/kakao
/api/v1/auth/google
/api/v1/tour
/api/v1/jobs/external
/api/v1/jobs/applications
/api/v1/jobs/favorites
/api/v1/gatherings
/api/v1/community/travel-posts
/api/v1/ai-matches
/api/v1/travel-guides
/api/v1/travel-recommendations
/api/v1/locations
/api/v1/regions
/api/v1/users/me
```

FE는 BE가 작성한 API 명세서를 기준으로 화면별 호출을 정리한다. FE 저장소의 Node API는 명세 확정 전 임시 목업으로만 사용한다.

배포 전 반드시 확인할 것:

- 로그인/회원가입 API 경로와 응답 포맷
- Kakao/Google OAuth redirect URI
- JWT access token 저장/전송 방식
- refresh token cookie 정책
- CORS 허용 origin
- 관광지 목록/상세 API
- 일자리 목록/상세 API
- 게더링 API
- 여행 추천/가이드 API
- 에러 응답 공통 포맷

## 최종 인스턴스/리소스 배치

최소 안정형 구조:

```text
VPC / 2 AZ

Public Subnet A
├── ALB
└── NAT Gateway A

Public Subnet B
├── ALB
└── NAT Gateway B

Private App Subnet A
└── ECS Fargate Task
    └── api container

Private App Subnet B
└── ECS Fargate Task
    └── api container

Private DB Subnet A
└── RDS PostgreSQL Primary

Private DB Subnet B
└── RDS PostgreSQL Standby 또는 DB Subnet Group

Private Cache Subnet A/B
└── ElastiCache Redis Subnet Group
```

초기 비용 절감형 구조:

```text
VPC / 2 AZ

Public Subnet A/B
└── ALB

Public Subnet A
└── NAT Gateway 1개

Private App Subnet A/B
└── ECS Fargate Service desired count 1

Private DB Subnet A/B
└── RDS PostgreSQL Single-AZ + DB Subnet Group

Private Cache Subnet A/B
└── ElastiCache Redis single node
```

최종 안정성을 우선하면 NAT Gateway 2개, RDS Multi-AZ, Redis replication group을 사용한다. 비용을 우선하면 NAT Gateway 1개, RDS Single-AZ, Redis single node로 시작할 수 있다.

## ECS Fargate 설정 초안

ECS Cluster:

```text
name: illowa-jeolla-main-cluster
launch type: Fargate
```

Task Definition:

```text
family: illowa-jeolla-main-api
container: api
image: <account-id>.dkr.ecr.ap-northeast-2.amazonaws.com/illowa-jeolla-main-api:<git-sha>
operating system family: LINUX
cpu architecture: X86_64
port: 8080
cpu: 512 또는 1024
memory: 1024 또는 2048
log driver: awslogs
```

ECR용 image는 `linux/amd64`로 빌드한다. Apple Silicon에서 로컬 기본값으로 만든 `arm64` image는 로컬 검증용이며, 위 `X86_64` task definition과 혼용하지 않는다.

초기 권장값:

```text
비용 절감형: 0.5 vCPU / 1GB
여유 있는 최소 운영형: 1 vCPU / 2GB
```

ECS Service:

```text
name: illowa-jeolla-main-api-svc
desired count: 1
subnets: private app subnet A/B
security group: ECS Task SG
target group: ALB target group
deployment type: rolling update
```

초기에는 API 프로세스에서 scheduler도 실행하므로 Auto Scaling을 사용하지 않는다. scheduler를 EventBridge Scheduler로 분리하거나 분산 lock을 적용한 뒤에만 아래 구성을 검토한다.

```text
Auto Scaling 후보:

min tasks: 1
desired tasks: 1
max tasks: 4
target CPU utilization: 60~70%
```

## ALB 구조

```text
ALB
├── Listener 80
│   └── redirect to 443
└── Listener 443
    └── target group: ECS api:8080
```

운영 URL과 ACM certificate를 준비하기 전 기반 생성 단계에서는 80 listener가 target group으로 직접 전달할 수 있다. 이 HTTP 경로는 초기 health 검증용이며, certificate 적용 후에는 위 구조처럼 80을 443으로 redirect한다. Vercel에서 호출하는 운영 API URL은 반드시 HTTPS를 사용한다.

현재 운영 도메인:

```text
illowa-jeolla.cloud -> Vercel
api.illowa-jeolla.cloud -> ALB
```

Vercel은 HTTPS로 제공되므로 브라우저가 직접 호출하는 BE도 HTTPS여야 한다. 외부 DNS에서 `api.illowa-jeolla.cloud`를 ALB로 연결하고 ACM certificate와 443 listener를 적용했다.

BE health check endpoint는 Actuator를 붙인 뒤 아래 형태로 둔다.

```text
GET /actuator/health/liveness
```

## 보안 그룹

```text
ALB Security Group
- inbound: 80, 443 from 0.0.0.0/0
- outbound: ECS Task SG 8080

ECS Task Security Group
- inbound: 8080 from ALB Security Group only
- outbound: RDS, Redis, External APIs

RDS Security Group
- inbound: 5432 from ECS Task Security Group only

Redis Security Group
- inbound: 6379 from ECS Task Security Group only
```

DB와 Redis는 외부 인터넷에 직접 열지 않는다.

## Redis / ElastiCache 설계

Redis는 운영에서 Spring Boot BE가 사용하는 캐시/토큰 상태 저장소로 둔다. FE는 Redis에 직접 접근하지 않는다.

예상 사용 목적:

- refresh token 저장 또는 token blacklist 관리
- OAuth 로그인 과정의 임시 state 저장
- 외부 API 응답 캐시
- rate limiting
- 짧은 TTL이 필요한 임시 데이터 저장

Redis 장애 시 영향은 사용 목적에 따라 달라진다. 단순 API 응답 캐시라면 성능 저하 수준으로 끝날 수 있지만, refresh token이나 OAuth state를 Redis에 저장하면 로그인 유지와 인증 흐름에 직접 영향이 생긴다. 따라서 인증 상태 저장소로 Redis를 사용할 경우 운영 안정화 단계에서는 single node보다 replication group 구성을 우선 검토한다.

초기 비용 절감형 구성:

```text
ElastiCache Redis 7.1
- node type: cache.t4g.micro
- single node
- Multi-AZ disabled
- automatic failover disabled
- private cache subnet group
- inbound 6379 from ECS Task Security Group only
- encryption at rest enabled
- encryption in transit enabled
- AUTH token enabled
- snapshot retention 1일
```

운영 안정형 구성:

```text
ElastiCache Redis Replication Group
- primary 1개 + replica 1개 이상
- Multi-AZ enabled
- automatic failover enabled
- private cache subnet group
- inbound 6379 from ECS Task Security Group only
- encryption at rest enabled
- encryption in transit enabled
- AUTH token enabled
- snapshot retention 3~7일
```

초기 Terraform module은 replication group 안에 cache cluster 1개를 두는 single-node 구성을 사용한다. 운영 안정형 전환 시 replica와 Multi-AZ/failover 입력을 추가한다.

```hcl
module "redis" {
  source = "../../modules/redis"

  replication_group_id        = "illowa-jeolla-main-redis"
  subnet_group_name           = "illowa-jeolla-main-redis-subnets"
  parameter_group_name        = "illowa-jeolla-main-redis"
  subnet_ids                  = module.network.private_data_subnet_ids
  security_group_id           = module.security_groups.redis_security_group_id
  preferred_availability_zone = "ap-northeast-2a"

  engine_version = "7.1"
  node_type      = "cache.t4g.micro"

  auth_token         = module.secrets.redis_auth_token
  auth_token_version = var.redis_auth_token_version
}
```

운영 안정형으로 전환할 때는 module에 replica 관련 입력을 추가하고 아래 값들을 적용한다.

```hcl
mode                       = "replication_group"
node_type                  = "cache.t4g.small"
replicas_per_node_group    = 1
automatic_failover_enabled = true
multi_az_enabled           = true
snapshot_retention_limit   = 7
```

Redis AUTH token은 Terraform 코드나 tfvars에 평문으로 두지 않는다. 현재 구현은 Terraform 1.11 이상의 ephemeral resource와 write-only 속성을 사용해 SSM Parameter Store, ElastiCache에 전달하며 plan/state에는 실제 값을 저장하지 않는다. ECS Task Definition에서는 SSM parameter를 `REDIS_PASSWORD` secret으로 주입한다.

## 운영 환경변수

BE 운영에서 필요한 환경변수:

```text
SPRING_PROFILES_ACTIVE=prod

POSTGRES_HOST
POSTGRES_PORT
POSTGRES_DB
POSTGRES_USER
POSTGRES_PASSWORD

REDIS_HOST
REDIS_PORT
REDIS_PASSWORD
REDIS_SSL

JWT_SECRET
JWT_ACCESS_EXPIRATION
JWT_REFRESH_EXPIRATION
JWT_COOKIE_SECURE

KAKAO_CLIENT_ID
KAKAO_CLIENT_SECRET
KAKAO_REDIRECT_URI
KAKAO_MAP_REST_API_KEY

GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET
GOOGLE_REDIRECT_URI

TOUR_INFO_KOREAN_API
TOUR_JOB_API_KEY
JUNNAM_PUBLIC_JOB_API

OPENAI_API_KEY
OPENAI_MODEL
```

운영에서는 아래 설정도 별도 profile로 분리하는 것이 좋다.

```text
spring.jpa.hibernate.ddl-auto=validate 또는 none
spring.flyway.enabled=true
server.forward-headers-strategy=framework
management.endpoints.web.exposure.include=health,info
management.endpoint.health.probes.enabled=true
```

민감한 값은 GitHub Actions secret에 직접 오래 보관하기보다 Secrets Manager 또는 SSM Parameter Store에 저장하고, ECS Task Role 또는 Execution Role로 읽는 구조를 우선한다.

## CI/CD 방향

FE main은 Vercel Git integration으로 배포한다. BE와 infra는 GitHub Actions를 사용한다.

FE main push:

```text
FE main push
  |
  v
Vercel build/deploy
  |
  +--> production 환경변수 주입
  +--> Vite build
  +--> Vercel CDN 배포
  +--> production URL 확인
```

BE main push:

```text
BE main push
  |
  v
GitHub Actions
  |
  +--> Gradle test
  +--> Docker image build
  +--> ECR push
  +--> ECS Task Definition 새 revision 등록
  +--> ECS Service update
  +--> ALB health check 확인
```

BE image tag는 `latest`만 쓰지 않고 git sha를 같이 사용한다.

```text
illowa-jeolla-main-api:<git-sha>
```

AWS 인증은 GitHub Actions OIDC + AWS IAM Role을 사용한다. 적용된 BE deploy role은 `illowa-jeolla/BE`의 `main` ref만 신뢰하며, ECR image push와 대상 ECS service 배포에 필요한 최소 권한만 가진다. 장기 AWS access key는 GitHub Secrets에 저장하지 않는다.

Terraform은 ECS task definition의 실행 설정을 관리하고, BE workflow는 현재 task definition을 바탕으로 image만 git SHA tag로 교체한 새 revision을 등록한다. GitHub Actions 배포 후 Terraform이 service를 이전 revision으로 되돌리지 않도록 ECS service의 `task_definition`은 Terraform lifecycle 변경 감지에서 제외한다.

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

초기에는 `terraform apply`를 자동 실행하지 않고 `workflow_dispatch` 수동 실행으로 두는 것이 안전하다. 인프라 변경은 앱 배포보다 영향 범위가 크기 때문이다.

## 단계별 실행 계획

### 1단계: FE/BE API 계약 안정화

- FE가 BE API 명세 기준으로 호출 경로와 응답 처리를 수정한다.
- BE는 API 명세와 실제 응답 포맷 차이를 줄인다.
- develop에서 FE/BE 통합 개발 테스트를 진행한다.

### 2단계: BE Docker 배포 준비

- BE Dockerfile 작성 완료
- BE `.dockerignore` 작성 완료
- prod profile 초안 작성 완료
- Actuator liveness health check 추가 완료
- 초기 제출 배포는 `ddl-auto: update` 사용
- 배포 안정화 후 migration 도구 도입 및 `ddl-auto: validate` 전환
- 로컬에서 BE image build 확인
- BE container 단독 실행 확인

### 3단계: Vercel FE 연동 준비

- React 앱의 API base URL 환경변수 정리
- Vercel production domain 확정
- 운영 domain 기준 OAuth callback 정리
- `vercel.json` SPA rewrite 적용
- Vercel production 환경변수에 BE HTTPS URL 등록

### 4단계: infra 레포 생성과 Terraform 기반 AWS 리소스 정의

- `illowa-jeolla/infra` 레포 생성
- Terraform HCL 디렉터리 구조 작성
- S3 backend와 native lockfile 구성
- GitHub Actions OIDC Role 정의
- Terraform fmt/validate/plan workflow 작성

### 5단계: AWS 기본 리소스 생성

- BE API용 Route 53 domain과 ACM certificate 준비
- Terraform state 및 community image S3 bucket 생성
- VPC 구성
- Public Subnet 2개 생성
- Private App Subnet 2개 생성
- Private DB/Cache Subnet 구성
- NAT Gateway 구성
- ECR 생성
- RDS PostgreSQL 생성
- ElastiCache Redis 생성
- ALB 생성
- ECS Cluster 생성
- Secrets Manager 또는 SSM Parameter Store 구성

### 6단계: BE ECS 배포

- BE image를 ECR에 push
- ECS Task Definition 등록
- ECS Service 생성
- ALB Target Group 연결
- `https://api.illowa-jeolla.cloud/actuator/health/liveness` 확인
- 주요 API 동작 확인
- OAuth redirect URI를 운영 API 도메인으로 변경
- CloudWatch 로그 확인

### 7단계: Vercel FE 배포 및 통합

- FE main을 Vercel production으로 배포
- Vercel production domain을 BE CORS와 OAuth 완료 redirect에 반영
- ECS task를 새 설정으로 재배포
- Vercel SPA deep link 확인
- FE에서 BE API 호출 확인

### 8단계: 운영 보강

- scheduler 분리 또는 분산 lock 적용 후 ECS Service Auto Scaling 검토
- RDS 백업/스냅샷 정책 확인
- Redis replication group 검토
- NAT Gateway 이중화 검토
- CloudWatch 알람 추가
- ALB access log 설정
- GitHub Actions 배포 자동화 완성
- 배포 실패 시 rollback 절차 정리

## ECS를 선택할 때 감수할 점

- Kubernetes 운영 경험은 EKS보다 적게 쌓인다.
- Helm, Kustomize, Ingress, ServiceAccount 같은 Kubernetes 리소스 학습은 하지 않는다.
- AWS ECS/Fargate에 종속된 운영 경험이 된다.

그럼에도 이번 프로젝트에서는 ECS 선택이 현실적이다. API 80개 규모의 Spring Boot 서버는 ECS Fargate로 충분히 운영 가능하며, FE/BE 분리 배포와 main branch CI/CD를 빠르게 안정화할 수 있다.

## 최종 판단

```text
개발:
- BE: Docker Compose + Spring Boot
- FE: Vite dev server + BE API 명세 기준 연동

전환:
- FE Node/SQLite 서버는 목업/프로토타입으로만 사용
- FE API 호출을 Spring BE API로 정리

운영:
- FE: Vercel
- BE: ECS Fargate + ECR + ALB
- DB/Cache: RDS + ElastiCache
- Asset: private S3
- Secret/Log: SSM Parameter Store + CloudWatch
- IaC: 별도 infra 레포 + Terraform HCL

CI/CD:
- FE main push -> Vercel 운영 배포
- BE main push -> BE 운영 배포
- infra main -> Terraform plan/apply
```

이 구조가 현재 팀 규모, FE/BE 분리 방향, 운영 배포 목표, CI/CD 자동화 목표를 모두 만족하는 가장 현실적인 방향이다.

# AWS / Infra 작업 로그

최종 갱신일: 2026-09-14

## 프로젝트 성격

이 프로젝트는 정식 상용 서비스가 아니라 공모전 제출 및 시연을 위한 배포 대상이다.

다만 단순 정적 배포만 하는 것이 아니라, 인프라 경험과 포트폴리오를 위해 ECS 중심의 AWS 구성을 실제로 만든다. 상용 서비스 수준의 고가용성까지 구현하는 것은 현재 범위가 아니다.

## 담당 범위

- AWS 인프라 설계
- `infra` 저장소 관리
- Terraform IaC 작성
- AWS 리소스 생성 및 검증
- BE AWS 배포 구조와 Vercel FE 연동 설계
- GitHub Actions CI/CD 작성 지원
- 운영 환경변수와 secret 주입 방식 정리
- 배포 전후 검증 기준 정리

BE/FE 기능 개발과 Vercel 설정은 각 담당자가 진행한다. AWS 배포에 필요한 Dockerfile, 운영 profile, health check, 환경변수 계약은 인프라 측에서 초안을 작성하고 담당자와 합의한다.

## 확정된 방향

### 환경

- Terraform 환경은 하나만 운영한다.
- 디렉터리 이름은 `environments/main`으로 고정한다.
- `dev`, `prod`, `demo` 환경은 현재 만들지 않는다.
- 실제로 환경 분리가 필요해질 때만 추가한다.

### AWS 구성

```text
FE React/Vite
-> Vercel

BE Spring Boot API
-> Docker
-> ECR
-> ECS Fargate API Service
-> ALB

Data
-> RDS PostgreSQL
-> ElastiCache Redis

Secrets / Logs
-> SSM Parameter Store
-> CloudWatch Logs

CI/CD
-> FE: Vercel Git integration
-> BE/infra: GitHub Actions + GitHub OIDC
```

### 애플리케이션 실행

- 별도 Batch Worker 서버와 SQS/DLQ는 현재 배포 범위에서 제외한다.
- AI 매칭 비동기 처리와 정기 scheduler는 기존처럼 BE API 프로세스 안에서 실행한다.
- ECS API desired count를 1로 유지해 scheduler 중복 실행을 방지한다.
- API task를 2개 이상으로 확장하려면 scheduler를 EventBridge Scheduler로 분리하거나 분산 lock을 먼저 적용한다.
- 프로세스 내부 `@Async` 작업은 API task 종료 시 복구되지 않을 수 있으며, 제출용 배포에서는 이 위험을 수용한다.

### 비용 및 가용성 기준

- AWS Region: `ap-northeast-2`
- Availability Zone: 2개
- NAT Gateway: 1개
- ECS API desired count: 1
- RDS: Single-AZ, 소형 인스턴스
- Redis: single node
- Vercel 연동 전에 BE API HTTPS domain과 ACM certificate 적용
- Multi-AZ, NAT 이중화, WAF, Auto Scaling은 초기 범위에서 제외

이 구성은 장애 대응용 상용 운영 구성이 아니다. 단일 NAT, Single-AZ RDS, single-node Redis를 사용하므로 각 리소스 장애 시 서비스 중단 가능성을 감수한다.

## 저장소 구성

```text
tour_gong/
├── BE/
├── FE/
└── infra/
```

GitHub 저장소:

```text
illowa-jeolla/BE
illowa-jeolla/FE
illowa-jeolla/infra
```

## 확정된 infra 구조

```text
infra/
├── bootstrap/
│   └── remote-state/
├── environments/
│   └── main/
│       ├── main.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
├── modules/
│   ├── network/
│   ├── ecr/
│   ├── alb/
│   ├── ecs-api/
│   ├── rds/
│   ├── redis/
│   ├── s3-assets/
│   ├── secrets/
│   └── github-oidc/
└── docs/
    ├── AWS_DEPLOYMENT_STRATEGY.md
    ├── aws-kiro.md
    ├── aws_log.md
    ├── DEPLOYMENT_CONTRACT.md
    └── RESOURCE_NAMING.md
```

## 현재 완료 상태

- [x] 단일 환경을 `environments/main`으로 확정
- [x] 별도 Batch Worker 서버와 SQS/DLQ를 배포 범위에서 제외
- [x] ECS 실행 모듈을 `ecs-api` 하나로 확정
- [x] Terraform 디렉터리 구조 생성
- [x] 미구현 모듈 디렉터리에 `.gitkeep` 추가
- [x] `environments/main` Terraform 뼈대 파일 생성
- [x] `DEPLOYMENT_CONTRACT.md` 문서 뼈대 생성
- [x] `RESOURCE_NAMING.md` 문서 뼈대 생성
- [x] `aws_log.md`를 `infra/docs`로 이동
- [x] 실제 BE/FE 코드를 기준으로 `DEPLOYMENT_CONTRACT.md` 초안 작성
- [x] 최신 BE/FE pull 이후 배포 영향 재검토
- [x] AI 비동기 처리, scheduler, pgvector 요구사항 문서 반영
- [x] 커뮤니티 이미지 S3 구현과 전체 scheduler 목록 재검토
- [x] BE 전체 Gradle test 통과
- [x] BE Docker image build 및 `prod` profile liveness 검증

AWS에는 Terraform state S3, Network, ECR, Security Group, 커뮤니티 이미지 S3, RDS, Redis, DB/Redis 비밀번호용 SSM Parameter Store와 읽기 IAM 정책을 적용했다.

## 최근 변경 이력

### 2026-09-14

아키텍처 및 문서:

- 별도 Batch Worker ECS Service와 SQS/DLQ를 초기 배포 구조에서 제거
- AI `@Async` 처리와 모든 scheduler를 ECS API task 하나에서 실행하도록 계약 변경
- scheduler 중복 방지를 위해 ECS API desired count를 1로 고정
- Terraform 단일 환경 경로를 `environments/main`으로 확정
- AWS 리소스 공통 prefix를 `illowa-jeolla-main`으로 확정
- 커뮤니티 이미지용 private S3 책임을 `modules/s3-assets`로 분리
- 최신 BE commit `82fe2a2`, FE commit `207c805` 기준으로 API 경로, scheduler, 환경변수, S3 및 pgvector 요구사항 재검토
- ECS runtime을 Linux `X86_64`, ECR 배포 image를 `linux/amd64`로 확정
- FE hosting을 Vercel로 변경하고 AWS FE bucket, CloudFront, OAC, FE deploy role을 범위에서 제거
- Terraform state S3와 커뮤니티 이미지 private S3는 유지
- `modules/s3-cloudfront` 빈 모듈 제거
- `bootstrap/remote-state`에 state bucket, versioning, SSE-S3, public access block, TLS 강제 policy 작성
- `environments/main/backend.tf`에 S3 native lockfile을 사용하는 partial backend 설정 추가
- remote state bootstrap AWS 적용 완료: 6개 생성, 변경 0, 삭제 0
- versioning, AES256 encryption, public access block, BucketOwnerEnforced, 비공개 policy 상태 검증 완료
- `environments/main`을 생성된 S3 backend와 `use_lockfile = true`로 초기화
- 이후 AWS resource apply는 코드와 plan을 사용자에게 먼저 제시하고 명시적 승인 후 실행

BE 배포 준비:

- `BE/Dockerfile` 추가: Java 17 Temurin Jammy multi-stage build와 비루트 `spring` 사용자 적용
- `BE/.dockerignore` 추가
- Actuator 의존성 추가
- Spring Security에서 `/actuator/health`와 하위 경로를 인증 없이 허용
- `BE/src/main/resources/application-prod.yaml` 추가
- 운영 profile에 Redis TLS, graceful shutdown, forwarded header, liveness probe 설정 추가
- `BE/.env.example`에 Redis TLS, AI limit/cron, 외부 공공 API, 커뮤니티 이미지 저장소 환경변수 추가
- 운영 DB migration 도입 전까지 `JPA_DDL_AUTO=update`, Spring Batch metadata 초기화는 `always`를 기본값으로 유지

검증 및 로컬 실행 환경:

- 전체 Gradle test 성공
- Apple Silicon에서 로컬 Docker image build 성공
- `prod` profile로 PostgreSQL 및 Redis 연결 성공
- `/actuator/health/liveness` 응답 `UP` 확인
- pull 이전에 생성돼 있던 `postgres:17-alpine` 로컬 컨테이너를 최신 Compose 정의인 `pgvector/pgvector:pg17`로 재생성했으며 기존 volume은 유지
- pgvector extension `0.8.6`과 `ai_tour_place_candidates`, `ai_job_candidates` 테이블 생성 확인
- smoke test용 API 컨테이너는 검증 후 삭제

### 2026-09-15

Network와 ECR Terraform:

- `modules/network` 구현
- VPC CIDR을 `10.0.0.0/16`으로 설정
- `ap-northeast-2a`, `ap-northeast-2c`에 public, private app, private data subnet을 각각 구성
- private app subnet은 단일 NAT Gateway를 공유하도록 구성
- private data subnet은 인터넷 기본 경로 없이 격리
- `modules/ecr`에 immutable tag, AES256 암호화, push scan, lifecycle policy 구성
- untagged image는 7일 후 정리하고 전체 image는 최근 30개를 유지
- `environments/main`에 AWS Provider, 공통 태그, Network/ECR module, 변수 및 output 연결
- main 환경용 `.terraform.lock.hcl` 생성

검증:

- `terraform fmt -check -recursive` 통과
- `terraform validate` 통과
- 원격 S3 state 기준 `terraform plan` 통과
- 적용 전 plan 결과: 23개 생성, 변경 0, 삭제 0
- Network와 ECR AWS 적용 완료: 23개 생성, 변경 0, 삭제 0
- 적용 후 재검증 plan 결과: 변경 사항 없음

Security Group과 Community Image S3 Terraform:

- ALB, ECS API, RDS, Redis security group을 `modules/security-groups`로 분리
- ALB는 public HTTP `80`, HTTPS `443`만 허용
- ECS API `8080`, RDS `5432`, Redis `6379`는 security group 참조로만 연결
- ECS API는 외부 API와 AWS 서비스 호출을 위해 outbound 허용
- 커뮤니티 이미지 private S3 bucket, public access block, BucketOwnerEnforced, AES256 암호화, versioning 구성
- 미완료 multipart upload는 7일 후 정리하고 noncurrent object version은 30일 후 정리
- 비보안 HTTP 요청을 거부하는 bucket policy 구성
- ECS API task role에 연결할 S3 object 읽기/쓰기/삭제 IAM policy 구성
- `terraform fmt -check -recursive`와 `terraform validate` 통과
- 적용 전 plan 결과: 19개 생성, 변경 0, 삭제 0
- Security Group과 Community Image S3 AWS 적용 완료: 19개 생성, 변경 0, 삭제 0
- 적용 후 재검증 plan 결과: 변경 사항 없음
- BE의 기존 `.gitignore` 로컬 변경은 이 작업에서 수정하거나 커밋하지 않음

RDS, Redis, Secrets Terraform:

- `modules/rds`에 PostgreSQL 17.11, `db.t4g.micro`, gp3 20 GiB, Single-AZ DB instance 구성
- RDS는 private data subnet과 기존 RDS security group을 사용하고 public access를 차단
- RDS storage encryption, 7일 backup, 강제 TLS, 삭제 방지와 final snapshot 구성
- `modules/redis`에 Redis 7.1, `cache.t4g.micro`, single-node replication group 구성
- Redis는 private data subnet과 기존 Redis security group을 사용하고 TLS/AUTH 및 저장 데이터 암호화 활성화
- `modules/secrets`에서 PostgreSQL과 Redis 비밀번호를 SSM SecureString으로 관리
- Terraform 1.11 이상의 ephemeral resource와 write-only 속성을 사용해 비밀번호를 plan/state에 저장하지 않도록 구성
- ECS task execution role에 추후 연결할 최소 권한 SSM 읽기 IAM policy 생성 코드 추가
- PostgreSQL 17.11과 Redis 7.1 및 선택한 micro instance/node의 서울 리전 제공 여부 확인
- `terraform fmt -check -recursive`, `terraform validate`, 원격 state 기준 `terraform plan` 통과
- 적용 전 저장 plan 결과: 9개 생성, 변경 0, 삭제 0
- RDS, Redis, Secrets AWS 적용 완료: 9개 생성, 변경 0, 삭제 0
- RDS PostgreSQL 17.11 상태 `available`, private access, storage encryption, deletion protection 확인
- ElastiCache Redis 상태 `available`, TLS required, AUTH, 저장 데이터 암호화 확인
- DB/Redis SSM parameter가 `SecureString` version 1로 생성됐으며 값은 출력하지 않고 metadata만 검증
- 적용 후 AWS가 `rds.force_ssl`의 apply method를 `pending-reboot`로 반환해 Terraform 코드도 동일하게 정합화
- 정합화 후 재검증 plan 결과: 변경 사항 없음

BE ECR image:

- BE `chore/aws-deployment-prep`의 commit `225fca632481` 기준 전체 Gradle test 통과
- Apple Silicon에서 ECS `X86_64` runtime에 맞춰 `linux/amd64` image로 교차 빌드
- ECR `illowa-jeolla-main-api:225fca632481` push 완료
- image digest `sha256:ae893108e82ea8ddba601aab259f10f227995f59eb216d4cf694c7faa0f9729e` 확인
- 원격 image의 `linux/amd64`, 비루트 `spring:spring`, port `8080`, Java entrypoint 확인
- ECR basic scan 완료: Critical 0, High 0, Medium 10, Low 3
- 탐지 항목은 Ubuntu Jammy 기반 `glibc`, `libc`, `perl` 계열 4개 CVE가 중복 package 단위로 집계된 결과이며 ECS 배포 전 기록

ALB와 ECS API Terraform:

- `modules/alb`에 internet-facing ALB, `ip` target group, HTTP/선택적 HTTPS listener 구성
- `/actuator/health/liveness`를 30초 interval, 5초 timeout, healthy 2회, unhealthy 3회로 구성
- ACM certificate가 없으면 HTTP forward, 설정하면 HTTP에서 HTTPS redirect 및 TLS 1.2 이상 HTTPS listener 사용
- `modules/ecs-api`에 ECS cluster, Fargate task definition, API service, CloudWatch log group 구성
- task runtime은 Linux `X86_64`, 0.5 vCPU, 1 GiB, image tag `225fca632481`로 구성
- ECR pull과 CloudWatch Logs 권한은 task execution role에 연결
- 기존 SSM 읽기 정책은 task execution role, community image S3 정책은 application task role에 연결
- RDS/Redis endpoint 및 DB/Redis SSM secret을 task definition에 연결
- scheduler 중복 방지를 위해 desired count 입력을 0 또는 1로 제한
- 운영 FE URL과 OAuth/JWT 값이 없으므로 초기 desired count는 0으로 설정
- 필수 일반 환경변수와 secret ARN 없이 desired count를 1로 올리는 plan 차단 동작 검증
- `terraform fmt`, `terraform validate`, 원격 state 기준 `terraform plan` 통과
- 적용 전 plan 결과: 12개 생성, 변경 0, 삭제 0
- ALB와 ECS 기반 AWS 적용 완료: 12개 생성, 변경 0, 삭제 0
- ALB 상태 `active`, ECS Service 상태 `ACTIVE`, desired/running/pending count `0/0/0` 확인
- 적용 후 재검증 plan 결과: 변경 사항 없음
- ALB DNS `illowa-jeolla-main-alb-778055198.ap-northeast-2.elb.amazonaws.com` 생성

ACM 인증서 준비:

- 보유 도메인 `cltrmp.cloud`의 백엔드 전용 주소를 `api.cltrmp.cloud`로 확정
- DNS는 가비아 네임서버에서 관리하며 `api` 레코드는 아직 미사용 상태임을 확인
- 외부 DNS에서 수동 검증할 ACM 인증서 요청용 `modules/acm` 추가
- 인증서가 발급되기 전에는 ALB HTTPS listener에 연결하지 않도록 요청과 연결 단계를 분리
- ACM 인증서 요청 AWS 적용 완료: 1개 생성, 변경 0, 삭제 0
- 가비아에 ACM DNS 검증 CNAME과 `api`에서 ALB로 향하는 CNAME 등록 완료
- 외부 DNS 조회로 두 CNAME의 전파를 확인하고 ACM 검증 `SUCCESS`, 인증서 상태 `ISSUED` 확인
- 발급된 인증서를 ALB 443 HTTPS listener에 연결하고 기존 HTTP listener를 HTTPS redirect로 전환
- ALB HTTPS 적용 결과: 1개 생성, 1개 변경, 삭제 0
- `http://api.cltrmp.cloud` 요청의 HTTPS `301` redirect 확인
- `https://api.cltrmp.cloud` 인증서 검증 성공 및 TLS 검증 결과 `0` 확인
- ECS desired count가 0이므로 HTTPS health 요청이 예상대로 `503`을 반환함
- ALB 의존성이 ECS IAM 전체에 전파되던 module-level 의존성을 제거하고 target group output에 listener 의존성을 한정
- Provider 경고를 제거하기 위해 HTTP listener의 forward/redirect action을 동적 블록으로 분리
- 최종 재검증 plan 결과: 변경 사항 없음

최종 도메인 전환 준비:

- 최종 서비스 도메인을 `illowa-jeolla.cloud`, 백엔드 주소를 `api.illowa-jeolla.cloud`로 확정
- 기존 `api.cltrmp.cloud` HTTPS 연결을 유지한 채 새 인증서를 병렬 발급하도록 ACM 모듈을 다중 인증서 구조로 확장
- 새 인증서 DNS 검증 전에는 ALB의 활성 인증서와 운영 URL을 변경하지 않음
- `api.illowa-jeolla.cloud` ACM 인증서 요청 AWS 적용 완료: 1개 생성, 변경 0, 삭제 0
- 기존 `api.cltrmp.cloud` 인증서와 ALB HTTPS listener는 그대로 유지
- 새 인증서 상태는 `PENDING_VALIDATION`이며 새 도메인의 DNS에 ACM 검증 CNAME을 등록해야 함
- `api.illowa-jeolla.cloud`의 ACM 검증 CNAME과 ALB CNAME 등록 및 외부 DNS 전파 확인
- 새 ACM 인증서의 도메인 검증 `SUCCESS`, 인증서 상태 `ISSUED` 확인
- ALB의 활성 인증서를 새 도메인 인증서로 교체하되 기존 `api.cltrmp.cloud` 인증서는 롤백용으로 유지
- ALB 443 listener 인증서 교체 적용 완료: 생성 0, 변경 1, 삭제 0
- `http://api.illowa-jeolla.cloud`의 HTTPS `301` redirect와 새 도메인 TLS 검증 성공 확인
- ECS desired count가 0이므로 HTTPS health 요청은 예상대로 `503`이며 최종 Terraform plan은 변경 사항 없음

### 2026-09-16

운영 secret 및 ECS API 기동:

- 사용자 제공 JWT/OAuth/API key 8개를 `/illowa-jeolla/main` 경로의 SSM Parameter Store `SecureString` Standard parameter로 등록하고 metadata 검증 완료
- Terraform이 관리하는 DB/Redis password를 포함해 전체 10개 parameter가 `SecureString`임을 확인
- 실제 secret 값은 Terraform 코드, `tfvars`, plan, state에 저장하지 않고 ECS task definition에는 parameter ARN만 연결
- ECS task execution role의 SSM 읽기 정책에 JWT/OAuth/Kakao Map/관광/일자리/OpenAI parameter ARN 추가
- 운영 FE origin, OAuth callback, JWT cookie, OpenAI embedding 및 AI match scheduler 일반 환경변수 반영
- 누락된 API key와 AI match 설정이 있으면 desired count 1 plan을 차단하도록 필수값 검증 범위 확장
- 일회성 Fargate task에서 `CREATE EXTENSION IF NOT EXISTS vector`를 실행하고 exit code 0 및 `CREATE EXTENSION` 로그 확인
- 일회성 DB bootstrap task definition은 실행 후 `INACTIVE` 처리
- 검증 plan 결과: task definition 교체 1, IAM policy/service 변경 2, 예상 밖 인프라 삭제 없음
- ECS API desired count를 1로 적용하고 task definition revision 2 배포 완료
- ECS Service desired/running/pending `1/1/0`, rollout `COMPLETED`, ALB target `healthy` 확인
- `https://api.illowa-jeolla.cloud/actuator/health` 및 liveness HTTPS 200, TLS 검증 결과 0 확인
- `https://illowa-jeolla.cloud` origin의 CORS preflight에 credentials 허용 및 정확한 origin 반환 확인
- CSRF endpoint가 HTTPS 200, 운영 origin CORS header와 `Secure` XSRF cookie를 반환함을 확인
- Kakao와 Google OAuth 시작 endpoint가 각 provider의 HTTPS 인증 주소로 302 redirect함을 확인
- 누락된 문자로 인해 잘못 등록됐던 Kakao REST API key를 BE 로컬 환경, SSM Parameter Store, ECS 일반 환경변수에 동일하게 반영
- ECS task definition revision 3으로 교체 배포하고 desired/running/pending `1/1/0`, rollout `COMPLETED`, ALB target `healthy` 확인
- Kakao 인증 페이지 요청에서 `KOE101`이 더 이상 반환되지 않음을 확인
- 인증되지 않은 보호 API 요청이 401을 반환함을 확인
- CloudWatch에서 PostgreSQL connection pool 연결과 Spring Boot 시작 완료 로그 확인
- 적용 후 Terraform plan 결과: 변경 사항 없음

Vercel 연결 확인:

- apex A record와 `www` CNAME의 공개 DNS 전파 확인
- 배포 bundle에 `https://api.illowa-jeolla.cloud`와 CSRF response token 우선 사용 변경 반영 확인
- Vercel 기본 배포 URL의 `/oauth/callback` deep link가 200을 반환해 SPA rewrite 적용 확인
- custom domain HTTPS certificate는 아직 발급 대기
- 현재 apex가 `www`로 redirect되므로 backend에 설정한 apex origin과 맞추기 위해 `illowa-jeolla.cloud`를 Vercel Primary Domain으로 변경해야 함

## 현재 애플리케이션 상태

### BE

확인된 내용:

- Spring Boot / Gradle
- Java 17
- Spring Boot 4.1.0
- Spring Batch 의존성과 Batch Job 존재
- 전역 scheduling과 여러 `@Scheduled` 작업 존재
- AI 후보 동기화 및 비활성 후보 정리 `@Scheduled` 작업 존재
- 커뮤니티 draft/삭제 게시글/S3 객체 삭제 재시도 scheduler 존재
- 만료 gathering과 삭제된 여행 가이드 정리 Spring Batch scheduler 존재
- AI 매칭과 여행 추천 요청은 Spring 내부 event와 `@Async`로 API 프로세스 안에서 처리
- `hibernate-vector`와 PostgreSQL `vector(1536)` 컬럼 사용
- 로컬 PostgreSQL은 `pgvector/pgvector:pg17` image 사용
- PostgreSQL 및 Redis 의존성 사용
- 로컬 `docker-compose.yml`은 PostgreSQL과 Redis 실행
- `application.yaml`에서 `.env`를 optional import
- Redis를 refresh token, OAuth state, 추천 cache/draft 등에 사용
- AWS SDK S3 client와 presigned GET URL 기반 커뮤니티 이미지 저장 구현 존재
- `prod`, `production` profile에서 localhost FE origin/callback을 거부하는 검증 존재
- multi-stage Dockerfile과 `.dockerignore` 존재
- `application-prod.yaml`과 `prod`, `production` profile용 FE 주소 검증 존재
- Actuator liveness health endpoint와 Security 허용 규칙 존재
- `ddl-auto: update` 사용 중
- 최신 확인 commit: BE `82fe2a2`, FE `207c805`

필요한 작업:

- [x] Dockerfile 작성
- [x] `.dockerignore` 작성
- [x] 운영 profile 초안 작성
- [ ] 운영 DB migration 방식 확정
- [x] Actuator와 liveness health endpoint 추가
- [x] Redis TLS/AUTH 연결 설정 추가
- [x] 운영 환경변수 목록 확정
- [x] RDS에서 `vector` extension 생성 방식 확정 및 실행
- [ ] API task가 1개일 때 내부 `@Async`와 scheduler 동작 검증
- [x] 커뮤니티 이미지 전용 private S3 bucket과 API task IAM 권한 생성
- [x] 로컬 Docker image build 및 실행 검증

2026-09-14 로컬 검증 결과:

- 전체 Gradle test 성공
- `illowa-jeolla-main-api:local` image build 성공
- image는 비루트 사용자 `spring:spring`으로 실행
- Temurin Jammy multi-architecture image 사용; 로컬 검증 image는 `arm64`, ECR 배포 image는 ECS `X86_64`에 맞춰 `linux/amd64`로 빌드
- `prod` profile로 PostgreSQL/Redis 연결 후 `/actuator/health/liveness` 응답 `UP` 확인
- 기존 로컬 PostgreSQL 컨테이너는 pull 전 `postgres:17-alpine` image였으므로 Compose 최신 정의인 `pgvector/pgvector:pg17`로 재생성
- pgvector extension `0.8.6`과 AI vector table 생성 확인

`ddl-auto: update`는 제출용 단기 배포에서는 사용할 수 있지만 데이터 변경 위험이 있다. 가능하면 `validate`와 migration 도구를 사용하며, 일정상 불가능하면 위험을 문서화한다.

### FE

확정된 방향:

- React/Vite 앱은 Vercel에서 배포
- FE 정적 hosting은 AWS Terraform 범위에서 제외
- 기존 Node/SQLite 서버는 운영 backend로 사용하지 않음
- Vercel production 환경변수에 BE HTTPS URL 주입
- Vercel production domain을 BE CORS와 OAuth 완료 redirect에 반영
- Vite SPA deep link를 위한 `vercel.json` rewrite 필요
- preview URL은 초기 CORS 허용 대상에서 제외

FE용 S3, CloudFront, OAC, AWS deploy role은 만들지 않는다.

### 비동기 처리와 scheduler

현재 AI 매칭은 API 컨테이너 내부 `@Async` listener에서 처리한다. 별도 Worker와 SQS를 도입하지 않으므로 API가 처리 중 종료되면 작업을 복구할 수 없는 위험을 수용한다.

AI 후보 데이터 동기화 cron도 API 프로세스에서 실행한다. 초기 ECS API desired count는 1로 유지하며, 수평 확장 전에는 scheduler 중복 실행 방지 장치를 별도로 마련해야 한다.

## Terraform 모듈별 책임

### `bootstrap/remote-state`

- Terraform state용 S3 bucket
- bucket versioning 및 encryption
- public access block
- state locking 방식

Terraform 1.10 이상의 S3 native lockfile을 사용한다. deprecated된 DynamoDB locking은 만들지 않는다.

### `modules/network`

- VPC
- Public Subnet A/B
- Private App Subnet A/B
- Private Data Subnet A/B
- Internet Gateway
- NAT Gateway 1개
- Route Table 및 Association

### `modules/ecr`

- API 이미지 저장소
- image scan on push
- lifecycle policy

### `modules/security-groups`

- ALB public HTTP/HTTPS ingress
- ALB에서 ECS API `8080` 접근
- ECS API에서 외부 API 및 AWS 서비스 접근
- ECS API에서 RDS `5432` 접근
- ECS API에서 Redis `6379` 접근

보안 그룹을 별도 모듈에서 생성해 ALB, ECS, RDS, Redis 사이의 순환 의존성을 방지한다.

### `modules/alb`

- Application Load Balancer
- listener
- target group
- `security-groups` 모듈에서 생성한 ALB security group 연결

### `modules/ecs-api`

- API task definition
- API ECS service
- task execution role 및 task role
- CloudWatch log group
- ALB target group 연결
- `security-groups` 모듈에서 생성한 ECS API security group 연결

### `modules/rds`

- PostgreSQL DB instance
- DB subnet group
- `security-groups` 모듈에서 생성한 RDS security group 연결
- parameter group
- backup policy

RDS는 public access를 차단하고 ECS security group에서만 5432 접근을 허용한다.

초기 구성은 PostgreSQL 17.11, `db.t4g.micro`, gp3 20 GiB, Single-AZ다. storage encryption, 7일 backup, TLS 강제, deletion protection과 final snapshot을 사용한다. `vector` extension은 RDS 생성 후 SQL로 별도 활성화한다.

### `modules/redis`

- ElastiCache subnet group
- Redis node 또는 replication group
- `security-groups` 모듈에서 생성한 Redis security group 연결
- encryption 설정

Redis는 public subnet에 배치하지 않고 ECS security group에서만 6379 접근을 허용한다. 초기 구성은 Redis 7.1, `cache.t4g.micro` 단일 노드이며 TLS/AUTH와 저장 데이터 암호화를 활성화한다.

### `modules/s3-assets`

- 커뮤니티 이미지 전용 private S3 bucket
- public access block 및 server-side encryption
- API task role에 연결할 object 읽기/쓰기/삭제 IAM policy
- 필요 시 CORS 및 lifecycle policy

### `modules/secrets`

- PostgreSQL 및 Redis 비밀번호를 SSM Parameter Store SecureString으로 생성
- Terraform state에 값이 남지 않도록 ephemeral resource와 write-only 속성 사용
- ECS task execution role에 연결할 해당 parameter 전용 읽기 IAM policy

비밀값 자체를 Terraform 코드나 `tfvars`에 평문으로 커밋하지 않는다. DB/Redis 비밀번호 회전 시 대응하는 version 변수를 증가시킨다. ECS task definition의 secret 주입과 IAM policy 연결은 `ecs-api` 모듈에서 수행한다.

### `modules/github-oidc`

- GitHub OIDC provider
- BE 배포 role
- Terraform 실행 role

장기 AWS access key 대신 OIDC를 사용한다.

## 작업 순서

### 1. 구조 및 계약

- [x] infra 디렉터리 구조 생성
- [x] `DEPLOYMENT_CONTRACT.md` 초안 작성
- [x] `RESOURCE_NAMING.md` 작성

### 2. 애플리케이션 배포 준비

- [x] BE Dockerfile 및 `.dockerignore`
- [x] BE 운영 profile 및 health check 초안
- [x] Vercel FE 연동 방향 확정

### 3. Terraform 기반

- [x] remote state bootstrap 코드 작성
- [x] remote state bootstrap AWS 적용 및 보안 설정 검증
- [x] network module
- [x] ECR module
- [x] `environments/main` provider/backend/module wiring

### 4. Asset 및 Vercel 연동

- [x] 커뮤니티 이미지 S3 module
- [x] BE HTTPS URL을 Vercel 환경변수에 반영
- [x] Vercel production origin을 BE CORS/OAuth 설정에 반영
- [ ] FE Vercel 통합 검증

### 5. 백엔드 데이터 및 실행 환경

- [x] RDS module 작성 및 plan 검증
- [x] Redis module 작성 및 plan 검증
- [x] secrets module 작성 및 plan 검증
- [x] RDS, Redis, secrets AWS 적용 및 상태 검증
- [x] ALB module 작성 및 plan 검증
- [x] ECS API module 작성 및 plan 검증

### 6. 수동 통합 배포

- [x] ECR image push
- [x] ECS API health check
- [ ] FE에서 BE API 호출
- [ ] API 내부 비동기 처리 및 scheduler 동작 검증

### 7. CI/CD

- [ ] GitHub OIDC module
- [ ] BE deploy workflow
- [ ] Terraform plan/apply 정책

### 8. 최종 검증

- [ ] 로그인 및 OAuth
- [ ] 주요 API smoke test
- [x] RDS 및 Redis 연결
- [ ] 내부 비동기 처리 및 scheduler 실행 결과
- [x] CloudWatch Logs
- [x] CORS 및 cookie 설정
- [ ] 비용 확인

## 현재 다음 작업

다음 작업은 Vercel에서 `illowa-jeolla.cloud`를 Primary Domain으로 설정하고 custom domain HTTPS certificate 발급을 완료하는 것이다. 이후 FE에서 회원가입, 일반 로그인, OAuth, token refresh와 주요 API를 smoke test하고 scheduler 실행 결과를 확인한다.

배포 계약의 `제안` 및 `미정` 항목은 BE/FE 담당자의 확인이 필요하다. ECS API를 2개 이상 실행하면 기존 scheduler가 중복 실행될 수 있으므로 초기 desired count는 1로 유지한다.

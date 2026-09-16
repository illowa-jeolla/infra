# Deployment Contract

최종 갱신일: 2026-09-16

이 문서는 Vercel FE와 AWS에 배포하는 BE API가 함께 지켜야 할 계약을 정의한다.

표기: `확정`은 현재 코드나 인프라 결정으로 확인된 값, `제안`은 담당자 합의가 필요한 기본값, `미정`은 추가 정보가 필요한 값이다.

## 1. 배포 단위

| 대상 | 배포 방식 | 외부 노출 | 상태 |
| --- | --- | --- | --- |
| FE | React/Vite -> Vercel | Vercel production domain | 확정 |
| BE API | Docker -> ECR -> ECS Fargate -> ALB | ALB | 확정 |

별도 Batch Worker ECS Service와 SQS/DLQ는 배포하지 않는다. BE의 비동기 처리와 scheduler는 API 프로세스 안에서 실행한다.

FE 정적 호스팅은 AWS 범위에서 제외한다. FE용 S3, CloudFront, OAC, AWS deploy role은 만들지 않는다.

```text
API: SPRING_PROFILES_ACTIVE=prod
```

초기 ECS API desired count는 1로 고정한다. API task를 수평 확장하면 scheduler가 중복 실행될 수 있으므로 그 전에 EventBridge Scheduler 분리 또는 분산 lock을 적용해야 한다.

## 2. BE 빌드 계약

| 항목 | 값 | 상태 |
| --- | --- | --- |
| Language | Java 17 | 확정 |
| Framework | Spring Boot 4.1.0 | 확정 |
| Build tool | Gradle Wrapper | 확정 |
| Test | `./gradlew test` | 확정 |
| Build | `./gradlew clean bootJar` | 확정 |
| Artifact | `build/libs/*.jar` | 확정 |
| Container port | `8080` | 확정 |
| Runtime | Java 17 JRE, non-root user | 확정 |
| ECS runtime platform | Linux / `X86_64` | 확정 |
| ECR image platform | `linux/amd64` | 확정 |

multi-stage Dockerfile과 `.dockerignore`를 사용한다. builder는 Java 17 JDK로 Gradle `bootJar`를 생성하고 runtime image는 Java 17 JRE와 non-root `spring` 사용자로 실행한다. image는 Git commit SHA로 태그하며 `latest`를 ECS 배포 기준으로 사용하지 않는다.

ECR에 push할 배포 image는 `docker buildx build --platform linux/amd64`로 생성한다. Apple Silicon에서 기본 빌드한 로컬 `arm64` image를 ECS `X86_64` task에 그대로 배포하지 않는다.

## 3. API 실행 역할

API:

- HTTP 요청을 `8080`에서 처리하고 ALB에 연결한다.
- AI 매칭 요청의 `@Async` listener와 `AiMatchProcessor`를 같은 API 프로세스에서 실행한다.
- AI 후보 동기화 및 정리 scheduler도 같은 API 프로세스에서 실행한다.

현재 BE에는 전역 `@EnableScheduling`, 여러 `@Scheduled` 클래스, Spring Batch Job이 있다. 별도 Worker로 분리하지 않으므로 배포 전 API 컨테이너 하나에서 이 작업들이 정상 실행되는지 확인해야 한다.

현재 API 프로세스에서 실행되는 scheduler:

| 작업 | 기본 주기 | Time zone |
| --- | --- | --- |
| AI 관광지 후보 동기화 | 매일 02:00 | Asia/Seoul |
| AI 전남 일자리 후보 동기화 | 매일 02:30 | Asia/Seoul |
| AI 관광 일자리 후보 동기화 | 매일 03:00 | Asia/Seoul |
| AI 비활성 후보 정리 | 매주 일요일 03:30 | Asia/Seoul |
| 커뮤니티 draft 정리 | 매일 04:00 | Asia/Seoul |
| 삭제 게시글 정리 | 매일 04:30 | Asia/Seoul |
| S3 객체 삭제 재시도 | 10분마다 | Asia/Seoul |
| 만료 gathering 정리 | 매주 월요일 00:00 | Asia/Seoul |
| 삭제된 여행 가이드 정리 | 매주 월요일 05:00 | Asia/Seoul |

현재 프로세스 내부 비동기 처리 대상은 AI 매칭과 여행 추천이다. 두 흐름 모두 transaction commit 이후 `@Async` listener에서 processor를 실행한다.

AI 매칭 흐름:

```text
API가 request context를 Redis에 저장
-> Spring ApplicationEvent 발행
-> 같은 API 프로세스의 @Async listener
-> AiMatchProcessor 실행
```

내부 event는 API 프로세스가 종료되면 복구할 수 없다. 별도 Worker와 메시지 큐를 두지 않는 제출용 배포에서는 이 위험을 수용한다.

AI 후보 동기화 cron은 desired count 1인 API task에서 실행한다. API task를 2개 이상으로 확장하려면 scheduler 중복 실행 방지 장치를 먼저 추가해야 한다.

## 4. Health check

| 항목 | 값 | 상태 |
| --- | --- | --- |
| API endpoint | `/actuator/health/liveness` | 확정 |
| Success | HTTP `200` | 확정 |
| Interval / timeout | 30초 / 5초 | 확정 |
| Healthy / unhealthy threshold | 2 / 3 | 확정 |

Actuator와 health probe를 활성화한다. ALB는 DB, Redis 등 외부 의존성 장애와 분리된 liveness endpoint를 사용하고, 의존 서비스 상태는 기본 health 또는 별도 운영 점검으로 확인한다.

Spring Security는 `/actuator/health`와 하위 경로를 인증 없이 허용한다. 다른 Actuator endpoint는 외부에 공개하지 않는다.

## 5. PostgreSQL

| 항목 | 값 | 상태 |
| --- | --- | --- |
| Engine | PostgreSQL | 확정 |
| Network | ECS security group에서만 접근 | 확정 |
| Public access | 비활성화 | 확정 |
| Availability | Single-AZ | 확정 |
| Target version | PostgreSQL 17.11 | 확정 |
| Instance / storage | `db.t4g.micro`, gp3 20 GiB | 확정 |
| Required extension | `vector` | 확정 |
| Current schema setting | `ddl-auto: update` | 확정 |
| Migration policy | 미정 | 미정 |

```text
POSTGRES_HOST
POSTGRES_PORT
POSTGRES_DB
POSTGRES_USER
POSTGRES_PASSWORD
```

`POSTGRES_PASSWORD`는 SSM Parameter Store의 `/illowa-jeolla/main/db/password`에서 ECS secret으로 주입한다. 가능하면 migration 도구 적용 후 `ddl-auto: validate`를 사용한다. `update`를 유지한다면 제출용 데이터 손실 위험을 수용해야 한다.

현재 Spring Batch metadata 설정은 `initialize-schema: always`다. API 컨테이너 시작 시 초기화 동작을 검증하고 운영 profile 값을 별도로 정해야 한다.

최신 BE는 `vector(1536)` 컬럼과 cosine distance 연산자를 사용한다. RDS 생성 후 애플리케이션 테이블보다 먼저 다음 extension이 생성되어야 한다.

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

로컬 환경은 `pgvector/pgvector:pg17` image를 사용한다. AWS 공식 extension 지원 목록에서 RDS PostgreSQL 17.11의 `pgvector` 지원을 확인했다. 단, RDS 생성만으로 extension이 자동 생성되지는 않으므로 첫 애플리케이션 배포 전에 위 SQL을 실행해야 한다.

## 6. Redis

| 항목 | 값 | 상태 |
| --- | --- | --- |
| Service | ElastiCache Redis | 확정 |
| Engine version / node | Redis 7.1, `cache.t4g.micro` | 확정 |
| Topology | single node | 확정 |
| Network | ECS security group에서만 접근 | 확정 |
| TLS / AUTH | 활성화 | 확정 |

```text
REDIS_HOST
REDIS_PORT
REDIS_PASSWORD
```

운영 profile은 `REDIS_SSL`로 Redis TLS를 활성화하며 기본값은 `true`다. AUTH token은 SSM Parameter Store의 `/illowa-jeolla/main/redis/password`에서 `REDIS_PASSWORD`로 주입한다. single node 장애 시 로그인, OAuth state, 추천 cache 기능이 영향을 받는 것을 허용하는 제출용 구성이다.

## 7. S3

애플리케이션용 S3는 커뮤니티 이미지 저장에만 사용한다. 별도로 Terraform remote state용 S3 bucket이 존재한다. FE 정적 파일은 Vercel에서 관리하며 AWS S3에 업로드하지 않는다.

```text
COMMUNITY_IMAGE_STORAGE=s3
COMMUNITY_IMAGE_S3_BUCKET
COMMUNITY_IMAGE_URL_EXPIRATION_MINUTES
AWS_REGION=ap-northeast-2
```

최신 BE에는 AWS SDK S3 client, object 업로드/삭제, presigned GET URL, 실패한 삭제 작업의 DB 기록 및 재시도 scheduler가 구현되어 있다. Terraform의 `s3-assets` 모듈이 이 bucket과 bucket policy를 소유한다.

- public access block을 모두 활성화한다.
- server-side encryption을 활성화한다.
- API task role에 대상 bucket의 `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject`만 허용한다.
- 운영 ECS에는 `COMMUNITY_IMAGE_STORAGE=s3`를 주입한다.
- presigned URL 기본 만료 시간은 30분이다.

## 8. BE 설정값

SSM Parameter Store에서 secret으로 주입:

```text
POSTGRES_PASSWORD
REDIS_PASSWORD
JWT_SECRET
KAKAO_CLIENT_SECRET
GOOGLE_CLIENT_SECRET
KAKAO_MAP_REST_API_KEY
TOUR_INFO_KOREAN_API
OPENAI_API_KEY
TOUR_JOB_API_KEY
JUNNAM_PUBLIC_JOB_API
```

일반 환경변수로 주입:

```text
SPRING_PROFILES_ACTIVE
POSTGRES_HOST
POSTGRES_PORT
POSTGRES_DB
POSTGRES_USER
REDIS_HOST
REDIS_PORT
REDIS_SSL
JPA_DDL_AUTO
SPRING_BATCH_JDBC_INITIALIZE_SCHEMA
JWT_ACCESS_EXPIRATION
JWT_REFRESH_EXPIRATION
JWT_COOKIE_SECURE
KAKAO_CLIENT_ID
KAKAO_REDIRECT_URI
GOOGLE_CLIENT_ID
GOOGLE_REDIRECT_URI
FRONTEND_OAUTH_CALLBACK_URI
FRONTEND_ORIGIN
OPENAI_MODEL
OPENAI_EMBEDDING_MODEL
OPENAI_EMBEDDING_DIMENSIONS
AI_MATCH_REQUEST_TTL
AI_MATCH_DAILY_LIMIT
AI_MATCH_TOUR_PLACE_CRON
AI_MATCH_JUNNAM_JOB_CRON
AI_MATCH_TOUR_JOB_CRON
AI_MATCH_CLEANUP_CRON
COMMUNITY_IMAGE_STORAGE
COMMUNITY_IMAGE_S3_BUCKET
COMMUNITY_IMAGE_URL_EXPIRATION_MINUTES
AWS_REGION
```

현재 Terraform이 관리하는 DB/Redis 비밀번호는 ephemeral random 값으로 생성해 SSM SecureString, RDS, ElastiCache의 write-only 속성으로 전달한다. 실제 값은 plan과 state에 저장하지 않는다. 비밀번호를 변경할 때는 대응하는 password version 변수도 증가시킨다. JWT와 OAuth client secret 등 사용자 제공 secret은 ECS 모듈 작성 시 별도 SSM parameter로 연결한다.

SSM parameter 읽기 정책은 ECS task execution role에 연결한다. 커뮤니티 이미지 S3 객체 접근 정책은 애플리케이션 AWS SDK가 사용하는 ECS task role에 연결한다.

BE `.env.example`의 `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`는 로컬 개발 예시일 뿐 ECS에 주입하지 않는다. ECS에서는 API task role의 임시 자격 증명을 사용한다.

`SPRING_PROFILES_ACTIVE=prod`를 사용하면 운영 FE 주소 검증과 `application-prod.yaml`이 활성화된다. `FRONTEND_ORIGIN`과 `FRONTEND_OAUTH_CALLBACK_URI`에 localhost를 넣으면 애플리케이션 시작이 실패한다. 운영 profile은 Redis TLS, forward header, graceful shutdown, Actuator health probe를 설정한다.

migration 도구가 아직 없으므로 첫 배포 기본값은 `JPA_DDL_AUTO=update`, `SPRING_BATCH_JDBC_INITIALIZE_SCHEMA=always`다. 제출용 초기 배포 후에는 migration 도구를 도입하고 `validate`로 전환한다.

## 9. Vercel FE 연동 계약

현재 React 앱 경로:

```text
FE/--main/travel-workation/react-app
```

FE 빌드와 배포 설정은 Vercel 프로젝트가 소유한다. AWS Terraform은 Vercel project, deployment, domain을 관리하지 않는다. 최종 Vercel production origin은 `https://illowa-jeolla.cloud`, BE HTTPS API URL은 `https://api.illowa-jeolla.cloud`로 확정했다.

```text
VITE_API_BASE_URL
VITE_KAKAO_MAP_JAVASCRIPT_KEY
VITE_AUTH_API_ENABLED
VITE_AUTH_API_ORIGIN
VITE_AUTH_API_BASE_PATH
```

`VITE_` 값은 bundle에 노출되므로 secret을 넣지 않는다. `VITE_API_BASE_URL`과 `VITE_AUTH_API_ORIGIN`에는 `https://api.illowa-jeolla.cloud`를 넣는다. Vercel 환경변수 변경 후에는 새 production deployment가 필요하다.

Vite SPA의 직접 경로 접근을 위해 FE project root에 `vercel.json` rewrite가 필요하다. Vercel preview URL은 배포마다 달라질 수 있으므로 초기 운영에서는 고정된 production domain만 BE CORS에 허용한다.

## 10. Vercel과 BE URL

- Vercel production URL은 `FRONTEND_ORIGIN`과 일치해야 한다.
- OAuth 완료 후 이동할 URL은 `FRONTEND_OAUTH_CALLBACK_URI`에 설정한다.
- 현재 BE CORS는 origin 하나와 credentials를 허용하므로 production URL을 정확히 설정한다.
- refresh token cookie는 운영에서 `Secure; SameSite=None`을 사용하므로 FE와 BE 모두 HTTPS여야 한다.
- `api.illowa-jeolla.cloud` CNAME과 ACM certificate 검증을 완료하고 ALB HTTPS listener에 연결한다.
- Kakao redirect URI는 `https://api.illowa-jeolla.cloud/api/v1/auth/kakao/callback`을 사용한다.
- Google redirect URI는 `https://api.illowa-jeolla.cloud/api/v1/auth/google/callback`을 사용한다.
- OAuth 완료 후 FE redirect는 `https://illowa-jeolla.cloud/oauth/callback`을 사용한다.

## 11. IAM

API task role:

- 커뮤니티 이미지 bucket의 `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject`
- 필요한 Parameter Store 값 읽기

Task execution role:

- ECR image pull
- CloudWatch Logs write
- task definition secret 조회

BE GitHub Actions는 장기 access key 대신 계정 단위 GitHub OIDC Provider와 `illowa-jeolla-main-be-deploy-role`을 사용한다. Role의 OIDC subject는 `repo:illowa-jeolla/BE:ref:refs/heads/main`, audience는 `sts.amazonaws.com`으로 제한한다. FE 배포는 Vercel이 담당하며 AWS OIDC role을 사용하지 않는다.

BE 배포 Role은 다음 작업만 허용한다.

- `illowa-jeolla-main-api` ECR repository에 image push
- 현재 ECS task definition 조회와 새 revision 등록
- `illowa-jeolla-main-api-svc` ECS service 조회와 update
- 지정된 ECS task execution role과 API task role을 `ecs-tasks.amazonaws.com`에 전달

Terraform은 ECS task definition의 환경변수, secret, CPU/Memory와 최초 service 구성을 관리한다. BE GitHub Actions가 배포한 task definition revision을 이후 Terraform apply가 이전 revision으로 되돌리지 않도록 ECS service의 `task_definition` 변경은 lifecycle에서 무시한다.

초기 ALB/ECS 기반은 desired count 0으로 적용했다. 운영 FE URL과 OAuth/JWT/API secret을 확정하고 SSM 연결 및 RDS `vector` extension 생성을 완료한 뒤 ECS Service의 desired count를 1로 전환했다. Terraform은 필수 일반 환경변수와 SSM secret ARN이 모두 설정되지 않은 상태에서 desired count를 1로 올리는 plan을 차단한다.

ALB 80 listener는 HTTPS로 redirect하고 443 listener는 발급된 `api.illowa-jeolla.cloud` ACM certificate를 사용해 target group으로 전달한다.

## 12. Logging

- API 전용 log group을 사용한다.
- 애플리케이션 로그는 stdout/stderr로 출력한다.
- token, password, OAuth code, API key, 전체 개인정보를 로그에 남기지 않는다.
- 내부 비동기 작업과 scheduler 로그에는 작업 식별자, 처리 결과와 처리 시간을 남긴다.
- 제출용 CloudWatch log retention 기본값은 14일이다.

## 13. 배포 차단 항목

- [ ] 단일 API task에서 내부 비동기 처리 및 scheduler 동작 검증
- [x] RDS `vector` extension 생성
- [ ] RDS vector query 검증
- [ ] ElastiCache TLS/AUTH 실제 연결 검증
- [ ] DB migration 또는 `ddl-auto` 위험 수용 결정
- [x] BE HTTPS API domain 및 ACM certificate 확정
- [x] Vercel production origin 및 OAuth callback 확정
- [x] FE Vercel 환경변수와 SPA rewrite 적용
- [x] 생성된 S3 객체 접근 정책을 ECS API task role에 연결
- [x] 생성된 SSM 읽기 정책을 ECS API task execution role에 연결
- [x] ECS API desired count 1 및 ALB health check 통과
- [x] Vercel custom domain HTTPS 및 Primary Domain 방향 검증

## 14. 담당자 확인 질문

BE 담당자:

1. 내부 비동기 작업과 scheduler를 단일 API task에서 실행해도 되는가?
2. API 프로세스 재시작 시 진행 중인 비동기 작업 유실 위험을 수용할 수 있는가?
3. ElastiCache TLS/AUTH 연결을 실제 운영 endpoint로 검증했는가?

FE 담당자:

1. Vercel production domain은 무엇인가?
2. AWS에서 전달한 HTTPS API URL을 Vercel production 환경변수에 반영했는가?
3. `vercel.json` SPA rewrite를 적용했는가?
4. 기존 Node/SQLite 서버는 Vercel 운영 배포에서 완전히 제외했는가?

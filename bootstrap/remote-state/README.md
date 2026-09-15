# Terraform Remote State Bootstrap

이 디렉터리는 `environments/main`보다 먼저 한 번 실행해 Terraform state용 S3 bucket을 만든다. Bootstrap 자체 state는 remote backend가 생기기 전이므로 로컬에 남는다. 해당 state는 secret처럼 취급하고 안전하게 보관한다.

## 생성 리소스

- 계정 ID가 포함된 private S3 bucket
- bucket versioning
- Amazon S3 관리형 암호화(SSE-S3)
- public access block
- TLS가 아닌 요청을 거부하는 bucket policy

DynamoDB lock table은 만들지 않는다. Terraform 1.10 이상에서 지원하는 S3 native lockfile을 `environments/main` backend가 사용한다.

## 실행

```bash
terraform init
terraform plan -out=bootstrap.tfplan
terraform apply bootstrap.tfplan
terraform output -raw state_bucket_name
```

실제 적용 전 AWS 자격 증명과 대상 account를 반드시 확인한다. 이 디렉터리에는 `prevent_destroy`가 설정돼 있으므로 일반적인 `terraform destroy`로 state bucket을 삭제할 수 없다.

Bucket 생성 후 출력된 이름을 사용해 main environment를 초기화한다.

```bash
terraform -chdir=../../environments/main init \
  -backend-config="bucket=<state-bucket-name>"
```

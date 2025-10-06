# Terraform 원격 백엔드 전환 가이드

## 배경
- 현재 `src/iac/terraform/terraform.tfstate` 및 `terraform.tfvars`가 로컬에 남아 있어 협업과 보안 측면에서 위험.
- `docs/REAL_WORLD_STRUCTURE.md`에서 권장하는 S3/DynamoDB 기반 원격 상태 저장이 미적용 상태.

## 목표
1. Terraform 상태 파일을 S3 버킷에 저장하고, DynamoDB 테이블로 State Lock을 구성한다.
2. 민감 변수는 `.tfvars` 대신 Parameter Store/Secrets Manager 또는 로컬 `.auto.tfvars` 예제로 이전한다.
3. 로컬에 남아 있는 상태/변수 파일을 제거하고 `.gitignore`를 강화한다.

## 세부 작업
1. **인프라 준비**
   - S3 버킷, DynamoDB 테이블을 Terraform 외부(별도 계정/콘솔)에서 생성하거나 Bootstrap Terraform으로 구성.
   - 버킷 정책과 SSE-KMS 적용 검토.
2. **backend.tf 수정**
   - `src/iac/terraform/envs/<env>/backend.tf`에서 `backend "s3" {}` 블록으로 전환.
   - `bucket`, `key`, `dynamodb_table`, `region`, `profile`(필요 시) 정의.
3. **변수 정리**
   - `terraform.tfvars` 내용을 `TFVARS_GUIDE.md`에 문서화하고, 실사용 값은 Parameter Store/Secrets Manager 연결 가이드로 대체.
   - 샘플은 `terraform.tfvars.example` 형태로만 저장.
4. **상태 이전**
   - `terraform init -migrate-state` 명령으로 로컬 상태를 원격으로 이전.
   - 이전 후 로컬 상태 파일 삭제 및 `.gitignore` 확인.
5. **CI/CD 반영**
   - `Makefile` 또는 `run/` 스크립트에서 원격 백엔드 초기화 명령을 갱신.
   - GitHub Actions/파이프라인이 동일한 backend 설정을 참조하도록 비밀 키 등록.

## 검증 체크리스트
- `terraform init` 시 원격 backend 연결 로그가 출력되는지 확인.
- `terraform state list`가 로컬 파일 없이 동작하는지 점검.
- `git status`에 state/vars 파일이 포함되지 않는지 확인.
- CI 환경에서 `terraform plan`이 문제없이 실행되는지 테스트.

## 참고 문서
- `docs/REAL_WORLD_STRUCTURE.md`
- `docs/improvements/20250921-improvement-checklist.md`

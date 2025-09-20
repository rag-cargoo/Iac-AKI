# Terraform Structure

이 디렉터리는 공용 모듈(`modules/`), 환경별 진입점(`envs/`), 상태 저장소(`state/`)로 구성됩니다.

## 사용 순서
1. 원하는 환경 디렉터리로 이동: `cd envs/production`
2. `terraform.tfvars` 값을 확인하거나 수정합니다.
3. `terraform init`, `terraform plan`, `terraform apply` 순으로 실행합니다.

## 디렉터리 구성
- `modules/` – VPC 네트워크, 보안 그룹, 컴퓨트 리소스 모듈
- `envs/<env>/` – 모듈을 조합하는 환경별 설정과 백엔드 정의
- `state/<env>/` – 로컬 상태 파일 기본 위치(실무에서는 S3/DynamoDB 등 원격 백엔드를 권장)

새로운 환경을 추가하려면 `envs/production`을 복제한 뒤 변수와 백엔드를 조정하면 됩니다.

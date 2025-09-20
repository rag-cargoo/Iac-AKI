# Repository Guidelines

## Project Structure & Module Organization
자세한 상위 설계와 리포 전략은 `docs/INFRA_SERVICE_STRUCTURE.md`에서 확인하세요.
Terraform은 `infra/terraform/modules/`에서 네트워크·보안·컴퓨트 모듈로 분리되며, 각 환경은 `infra/terraform/envs/<environment>/`에서 모듈을 조합합니다. Ansible은 `infra/ansible/roles/`의 역할 기반 구조(예: `docker_engine`, `swarm_manager`, `swarm_worker`)와 `playbooks/` 하위의 실행 단위 플레이북으로 구성됩니다. 동적 인벤토리는 `infra/ansible/inventory_plugins/swarm.py` 스크립트를 통해 제공되며 `ansible.cfg`가 기본 인벤토리로 참조합니다. 실행 스크립트는 `scripts/bin/`, 진단 및 보조 도구는 `scripts/tools/`, 문서는 `docs/` 및 `documentation/` 아래에 둡니다.

## Build, Test, and Development Commands
- `make setup_env` — Terraform output을 로드하고 SSH 설정 및 환경 변수를 갱신합니다.
- `make run` — 환경 설정 후 `ansible-playbook infra/ansible/playbooks/cluster.yml`을 실행해 전체 클러스터를 구성합니다.
- `cd infra/terraform/envs/production && terraform init && terraform plan && terraform apply` — 프로비저닝 또는 업데이트 시 표준 순서를 따릅니다.
- `ansible-playbook infra/ansible/roles/docker_engine/tests/test.yml` — 기본 연결 상태를 점검합니다.

## Coding Style & Naming Conventions
YAML은 두 칸 들여쓰기를 유지하고 역할별 `tasks/`, `defaults/`, `tests/` 구조를 따릅니다. Terraform 모듈은 snake_case 변수와 `variables.tf`·`outputs.tf` 인터페이스를 명시하고, 환경 진입점은 모듈 호출 순서를 네트워크 → 보안 → 컴퓨트로 유지합니다. Shell 스크립트는 POSIX 구문과 대문자 환경 변수를 사용하며, Python 스크립트(`inventory_plugins/swarm.py`)는 `black` 스타일과 f-string을 일관되게 사용합니다.

## Testing Guidelines
클러스터 변경 전 `terraform plan` 결과를 PR에 첨부하고, 적용 후 `terraform output`을 캡처합니다. Ansible 작업은 역할 단위 테스트(`roles/<role>/tests/`) 또는 `playbooks/verify.yml`로 검증하며, `docker service ls`와 `docker service ps`로 Swarm 상태를 확인합니다. 가능하다면 CI에서 `ansible-lint`와 Terraform `validate`를 실행하여 포맷 및 규칙 위반을 조기에 발견합니다.

## Commit & Pull Request Guidelines
커밋 메시지는 Conventional Commits(`feat:`, `fix:`, `refactor:` 등)를 사용하고, Terraform/Ansible 변경은 어떤 모듈과 역할이 영향을 받는지 본문에 명시합니다. PR에는 Terraform 플랜 요약, Ansible 실행 로그 또는 Swarm 검증 결과를 포함하고, 관련 이슈나 문서 링크를 추가합니다. 구조적 변경 시 `docs/REAL_WORLD_STRUCTURE.md` 업데이트 여부를 확인한 뒤 리뷰어를 태그합니다.

## Security & Access Tips
민감한 키와 상태 파일은 커밋하지 말고, 실무에서는 S3/DynamoDB 등 원격 백엔드를 사용하도록 `backend.tf`를 업데이트하세요. SSH 구성을 변경할 때는 직접 수정하지 말고 `scripts/bin/setup_project_env.sh`를 다시 실행해 관리 블록을 재생성합니다. 로그나 Terraform 출력 공유 시 공개 IP, 키 경로, 계정 정보는 마스킹하고 노출이 의심되면 키를 즉시 회전하십시오.

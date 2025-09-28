# Repository Guidelines

## Project Structure & Module Organization
자세한 상위 설계와 리포 전략은 `docs/INFRA_SERVICE_STRUCTURE.md`에서 확인하세요.
Terraform은 `src/iac/terraform/modules/`에서 네트워크·보안·컴퓨트 모듈로 분리되며, 각 환경은 `src/iac/terraform/envs/<environment>/`에서 모듈을 조합합니다. Ansible은 `src/iac/ansible/roles/`의 역할 기반 구조(예: `docker_engine`, `swarm_manager`, `swarm_worker`)와 `playbooks/` 하위의 실행 단위 플레이북으로 구성됩니다. 동적 인벤토리는 `src/iac/ansible/inventory_plugins/swarm.py` 스크립트를 통해 제공되며 `ansible.cfg`가 기본 인벤토리로 참조합니다. 실행/운영 스크립트와 단계별 가이드는 `run/` 아래에서 관리합니다.

## Build, Test, and Development Commands
- `make setup_env` — Terraform output을 로드하고 SSH 설정 및 Docker 컨텍스트를 전환합니다.
- `make run` — 환경 설정 후 `ansible-playbook src/iac/ansible/playbooks/cluster.yml`을 실행해 전체 클러스터를 구성합니다.
- `make tf-init / tf-plan / tf-apply / tf-destroy` — 루트에서 Terraform 작업을 수행합니다. 다른 환경은 `TF_ENV_DIR` 변수로 지정합니다.
- `ansible-playbook src/iac/ansible/roles/docker_engine/tests/test.yml` — 기본 연결 상태를 점검합니다.
- 추가 서비스/모니터링은 `run/` 디렉터리를 통해 단계별로 실행합니다. 명령 실행 전 `source run/common/setup_env.sh` 또는 `make setup_env`로 Docker 컨텍스트를 `swarm-manager`로 전환한 뒤 진행하세요. 터널 연결은 `make tunnel`을 활용할 수 있습니다.

## Coding Style & Naming Conventions
YAML은 두 칸 들여쓰기를 유지하고 역할별 `tasks/`, `defaults/`, `tests/` 구조를 따릅니다. Terraform 모듈은 snake_case 변수와 `variables.tf`·`outputs.tf` 인터페이스를 명시하고, 환경 진입점은 모듈 호출 순서를 네트워크 → 보안 → 컴퓨트로 유지합니다. Shell 스크립트는 POSIX 구문과 대문자 환경 변수를 사용하며, Python 스크립트(`inventory_plugins/swarm.py`)는 `black` 스타일과 f-string을 일관되게 사용합니다.

## Testing Guidelines
클러스터 변경 전 `terraform plan` 결과를 PR에 첨부하고, 적용 후 `terraform output`을 캡처합니다. Ansible 작업은 역할 단위 테스트(`roles/<role>/tests/`) 또는 `playbooks/verify.yml`로 검증하며, `docker service ls`와 `docker service ps`로 Swarm 상태를 확인합니다. 가능하다면 CI에서 `ansible-lint`와 Terraform `validate`를 실행하여 포맷 및 규칙 위반을 조기에 발견합니다.

## Commit & Pull Request Guidelines
커밋 메시지는 Conventional Commits(`feat:`, `fix:`, `refactor:` 등)를 사용하고, Terraform/Ansible 변경은 어떤 모듈과 역할이 영향을 받는지 본문에 명시합니다. PR에는 Terraform 플랜 요약, Ansible 실행 로그 또는 Swarm 검증 결과를 포함하고, 관련 이슈나 문서 링크를 추가합니다. 구조적 변경 시 `docs/REAL_WORLD_STRUCTURE.md` 업데이트 여부를 확인한 뒤 리뷰어를 태그합니다.

## Security & Access Tips
민감한 키와 상태 파일은 커밋하지 말고, 실무에서는 S3/DynamoDB 등 원격 백엔드를 사용하도록 `backend.tf`를 업데이트하세요. SSH 구성을 변경할 때는 직접 수정하지 말고 `run/common/setup_env.sh`를 다시 실행해 관리 블록을 재생성합니다. 로그나 Terraform 출력 공유 시 공개 IP, 키 경로, 계정 정보는 마스킹하고 노출이 의심되면 키를 즉시 회전하십시오.

## Improvement Checklist Workflow
- 개선 과제는 `docs/improvements/` 디렉터리의 날짜 접두사 파일(예: `20250921-improvement-checklist.md`)에서 관리하고, 모든 항목을 완료하면 파일명을 `-completed` 접미사로 변경합니다.
- Codex CLI 세션이 새로 시작되더라도 해당 문서를 먼저 확인해 진행 상황을 파악합니다.
- 개선 항목은 사용자 요청이 있을 때만 처리합니다. 사용자가 "이제 무엇을 해야 하지?" 등으로 진행 상황을 물으면 최신 체크리스트의 미완료 항목과 `진행 메모` 섹션을 바탕으로 다음 작업 후보를 안내하고, 실제 수행 여부를 질문하세요.
- 특이 사항이나 보류 중인 작업은 체크리스트 파일의 `진행 메모` 섹션에 간단히 기록해 두어 재시작 시 빠르게 맥락을 복구합니다.

## Git & Documentation Policy
- Codex는 개발/운영 작업에 집중하며, `git add`·`commit`·`push`와 같은 Git 명령이나 문서 작성/정리는 사용자가 명확히 요청할 때만 수행합니다.
- 사용자가 "정리할까?", "커밋해줘" 등으로 물어보면 현재 변경 사항을 요약하고 필요한 명령을 안내하거나 실행 여부를 확인합니다.
- 진행 중 수시로 문서화가 필요하다면 체크리스트의 `진행 메모`나 관련 문서 위치만 업데이트하고, 대규모 문서/리포트 작성은 사용자 요청 후 진행하세요.

# Repository Guidelines (Codex)

## Project Structure & Module Organization
- 모든 실습은 `labs/<lab-id>/` 아래에 격리됩니다. 현재 활성 실습은 `labs/01-lab-docker-swarm/`입니다.
- 각 실습은 `src/terraform`, `src/ansible`, `src/run`, `docs/` 하위 구조만 사용합니다. 공통 모듈을 루트에 두지 않습니다.
- Terraform은 `src/terraform/modules/`의 모듈을 `src/terraform/envs/<environment>/`에서 조합합니다. 실습에서는 로컬 상태만 사용하고 종료 후 정리합니다.
- Ansible은 역할 대신 `playbooks/` + `tasks/` 구조를 사용합니다. 필요한 변수는 플레이북의 `vars` 블록에서 정의하며, 동적 인벤토리는 `src/ansible/inventory_plugins/swarm.py`가 제공합니다.
- 실행/운영 스크립트와 단계별 가이드는 `src/run/` 하위에서 관리합니다. 서비스별 Docker stack 정의는 `src/run/stacks/`에 둡니다.

## Build, Test, and Development Commands
- 실습 디렉터리로 이동 후 실행합니다. (예) `cd labs/01-lab-docker-swarm`
- `make tf-init / tf-plan / tf-apply / tf-destroy` — Terraform 환경(`src/terraform/envs/production`)을 대상으로 작업합니다. 다른 환경은 `make TF_ENV_DIR=... tf-plan`처럼 지정합니다.
- `make setup_env` — Terraform output을 로드하고 SSH 설정 및 Docker 컨텍스트를 전환합니다.
- `make run` — `setup_env` 수행 후 `ansible-playbook src/ansible/playbooks/cluster.yml`을 실행해 Swarm을 구성합니다.
- `make 01-lab-docker-swarm-monitoring_deploy / 01-lab-docker-swarm-monitoring_remove` — 모니터링 스택을 배포/제거합니다.
- 루트에서는 `make 01-lab-docker-swarm-init`(최초 1회), `make 01-lab-docker-swarm-run`(plan→apply→Ansible), `make 01-lab-docker-swarm-tf-destroy`를 주요 워크플로로 사용하세요. 필요 시 `make 01-lab-docker-swarm-tf-plan`/`...-tf-apply`, `make 01-lab-docker-swarm-setup_env`, `make 01-lab-docker-swarm-tunnel`, `make 01-lab-docker-swarm-monitoring_{deploy,remove}` 같은 보조 타깃으로 개별 작업을 실행할 수 있습니다.

## Coding Style & Naming Conventions
- YAML은 두 칸 들여쓰기를 유지하고, 플레이북 이름은 목적별(`cluster.yml`, `monitoring.yml`)로 구분합니다.
- Terraform 변수는 snake_case를 사용하며 `variables.tf` · `outputs.tf` 인터페이스를 명확히 합니다.
- Shell 스크립트는 POSIX 구문과 대문자 환경 변수를 사용합니다.
- Python 스크립트(`inventory_plugins/swarm.py`)는 `black` 스타일과 f-string을 일관되게 사용합니다.

## Testing Guidelines
- Terraform 변경 전 `terraform -chdir=src/terraform/envs/production plan` 결과를 PR에 첨부하고, 적용 후 `terraform output`을 캡처합니다.
- Ansible 작업은 플레이북 실행 결과 또는 `src/run/common/diagnose_env.sh`로 확인합니다.
- Docker Swarm 상태는 `docker service ls`와 `docker service ps`로 검증합니다.
- 가능하다면 CI에서 `ansible-lint`와 `terraform validate`를 실행합니다.

## Commit & Pull Request Guidelines
- 커밋 메시지는 Conventional Commits(`feat:`, `fix:`, `refactor:` 등)를 사용합니다.
- Terraform/Ansible 변경 시 어떤 실습(`labs/01-lab-docker-swarm`)과 어떤 모듈/플레이북이 영향을 받는지 본문에 명시합니다.
- PR에는 Terraform 플랜 요약, Ansible 실행 로그 또는 Swarm 검증 결과를 포함하고, 관련 이슈나 문서 링크를 추가합니다.
- 구조 변경 시 `docs/INFRA_SERVICE_STRUCTURE.md`와 실습 `README.md` 업데이트 여부를 확인합니다.

## Security & Access Tips
- 실습에서는 로컬 tfstate만 사용하지만, 민감한 키와 상태 파일은 커밋하지 않습니다.
- SSH 구성을 변경할 때는 `src/run/common/setup_env.sh`를 다시 실행해 관리 블록을 재생성합니다.
- 로그나 Terraform 출력 공유 시 공개 IP, 키 경로, 계정 정보는 마스킹하고 노출이 의심되면 키를 즉시 회전하십시오.

## Improvement Checklist Workflow
- 개선 과제는 `docs/improvements/` 디렉터리의 날짜 접두사 파일(예: `20250921-improvement-checklist.md`)에서 관리하고, 모든 항목을 완료하면 파일명을 `-completed` 접미사로 변경합니다.
- Codex CLI 세션이 새로 시작되더라도 해당 문서를 먼저 확인해 진행 상황을 파악합니다.
- 개선 항목은 사용자 요청이 있을 때만 처리합니다. 사용자가 "이제 무엇을 해야 하지?" 등으로 진행 상황을 물으면 최신 체크리스트의 미완료 항목과 `진행 메모` 섹션을 바탕으로 다음 작업 후보를 안내하고, 실제 수행 여부를 질문하세요.
- 특이 사항이나 보류 중인 작업은 체크리스트 파일의 `진행 메모` 섹션에 간단히 기록해 두어 재시작 시 빠르게 맥락을 복구합니다.

## Git & Documentation Policy
- Codex는 개발/운영 작업에 집중하며, `git add`·`commit`·`push`와 같은 Git 명령이나 문서 작성/정리는 사용자가 명확히 요청할 때만 수행합니다.
- 사용자가 "정리할까?", "커밋해줘" 등으로 물어보면 현재 변경 사항을 요약하고 필요한 명령을 안내하거나 실행 여부를 확인합니다.
- 진행 중 수시로 문서화가 필요하다면 실습 `docs/` 또는 체크리스트의 `진행 메모`만 업데이트하고, 대규모 문서/리포트 작성은 사용자 요청 후 진행하세요.

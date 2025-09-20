# Production-Ready Project Structure

## Overview
이 문서는 AWS 기반 Docker Swarm 자동화 프로젝트를 실무 환경에 맞게 구성하기 위한 표준 구조와 워크플로우를 설명합니다. 모든 변경 사항은 `refactor-env-automation` 브랜치에서 진행되며, Terraform과 Ansible 레이어를 명확히 분리하고 스크립트 및 문서를 체계화합니다.

## Terraform Layout
- `Iac/TERRAFORM/modules/`에 네트워크, 보안, 컴퓨트 모듈을 분리해 재사용성을 확보합니다.
- `Iac/TERRAFORM/envs/<environment>/`는 환경별 진입점을 제공하며, `backend.tf`로 원격 상태 저장 위치를 선언하고 `terraform.tfvars`에 환경 값을 정의합니다. 스크립트 실행 시 `TERRAFORM_ENVIRONMENT` 변수를 설정하면 특정 환경 디렉터리를 선택할 수 있습니다.
- 모든 모듈은 `variables.tf`와 `outputs.tf`를 포함해 인터페이스를 명시하며, `README.md`에 사용법을 정리합니다.

## Ansible Layout
- `Iac/ANSIBLE/roles/` 디렉터리에 역할별 디렉터리를 생성하고 `tasks/`, `defaults/`, `handlers/`, `tests/` 구조를 유지합니다.
- 환경별 인벤토리는 `Iac/ANSIBLE/inventory/<environment>/hosts.yml`에 보관하며, 동적 인벤토리 스크립트는 `inventory_plugins/`로 이동합니다.
- 주요 플레이북은 `Iac/ANSIBLE/playbooks/`에 두며 `cluster.yml`, `bootstrap.yml`, `verify.yml` 등 목적에 따라 나누고, `site.yml`에서 필요한 플레이북을 호출합니다.

## Scripts & Tooling
- 실행 스크립트는 `scripts/bin/`, 진단 도구는 `scripts/tools/`, 공용 함수는 `scripts/lib/`에 배치합니다.
- `Makefile`은 빌드/테스트/배포 명령을 래핑하고, CI 파이프라인은 동일한 목표를 호출해 일관성을 유지합니다.
- Terraform, Ansible 각각에 대해 `pre-commit` 훅과 Lint를 구성해 기본 검증을 자동화합니다.

## CI/CD & Testing
- 파이프라인 단계: Terraform `plan` → 승인 → `apply` → Ansible 배포 → Docker Swarm 상태 점검(`docker service ls`).
- Ansible 역할 단위 테스트는 `molecule` 또는 `ansible-lint`로 실행하며, Terraform은 `terraform validate`와 `terratest`(선택)를 적용합니다.

## Migration Checklist
1. 기존 Terraform 상태 파일을 새 `envs/<environment>` 디렉터리로 이동하고 `backend.tf`를 설정합니다.
2. `scripts/bin/setup_project_env.sh`를 통해 환경 변수를 갱신한 뒤 Ansible 인벤토리 경로를 업데이트합니다.
3. 새 플레이북(`playbooks/cluster.yml`)으로 Swarm을 재배포하고, 테스트 플레이북을 `roles/<role>/tests/`로 이동합니다.
4. CI/CD 설정을 업데이트해 새로운 디렉터리와 명령 경로를 사용하도록 합니다.

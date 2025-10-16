# Production-Ready Project Structure

## Overview
이 문서는 실습 기반 저장소를 실무 환경으로 확장할 때 고려해야 할 구조와 워크플로우를 설명합니다. 현재 리포는 `labs/<lab-id>/` 아래에 실습을 격리하지만, 동일한 규칙을 적용해 프로덕션 저장소를 구성할 수 있습니다.

## Terraform Layout
- 실습에서는 `labs/<lab-id>/src/terraform/`에 모듈(`modules/`)과 환경별 진입점(`envs/<environment>/`)을 배치합니다.
- 실무에서는 동일 구조를 유지하되 원격 상태 백엔드(S3 + DynamoDB 등)와 `terraform.tfvars` 템플릿을 별도 리포 또는 Parameter Store로 분리합니다.
- 모든 모듈은 `variables.tf`, `outputs.tf`, `README.md`를 포함해 인터페이스를 명확히 합니다.

## Ansible Layout
- 학습용 실습은 `playbooks/` + `tasks/` 조합으로 단순화했지만, 실무에서는 역할(`roles/`)과 핸들러, 템플릿을 활용한 계층형 구조가 유리합니다.
- 동적 인벤토리 스크립트는 `labs/<lab-id>/src/ansible/inventory_plugins/`에 두고, 프로덕션에서는 별도 패키지로 재사용하거나 Parameter Store/Service Discovery와 연계합니다.
- 주요 플레이북은 `playbooks/cluster.yml`, `bootstrap.yml`, `verify.yml`처럼 목적별로 유지합니다.

## Scripts & Tooling
- 실습의 `src/run/` 구조를 그대로 확장해, 공통 스크립트는 `common/`, 서비스별 절차는 `monitoring/`, `logging/` 등으로 분리합니다.
- 루트 `Makefile`은 각 실습 `Makefile`을 프록시하지만, 프로덕션에서는 `make terraform-plan`, `make ansible-deploy`처럼 공통 명령을 루트에 직접 정의할 수 있습니다.
- Terraform/Ansible 모두 `pre-commit`, `terraform fmt`, `ansible-lint` 등을 활용해 기본 검증을 자동화합니다.

## CI/CD & Testing
- 파이프라인 단계 예시: Terraform `plan` → 수동 승인 → `apply` → Ansible 배포 → Docker Swarm 상태 점검(`docker service ls`, `docker service ps`).
- Ansible 플레이북 및 태스크는 `ansible-lint`, `molecule`로 검증하고, Terraform은 `terraform validate`, `terratest`(선택)을 적용합니다.
- 모니터링 스택 배포는 Swarm이나 Kubernetes의 GitOps 파이프라인(Argo CD 등)으로 이관할 수 있습니다.

## Migration Checklist
1. 실습에서 사용한 로컬 tfstate를 원격 백엔드로 이전하고, 상태 잠금/버전 관리를 활성화합니다.
2. `labs/<lab-id>/src/run/common/setup_env.sh`와 같은 스크립트를 조직 표준에 맞춰 리팩터링하거나 중앙 관리 스크립트로 통합합니다.
3. Ansible 구조를 역할 기반으로 확장하고, 공통 역할은 별도 패키지/레포로 분리합니다.
4. CI/CD 파이프라인을 업데이트해 새로운 디렉터리와 명령 경로를 사용하도록 합니다.

실습 구조를 기반으로 하되, 실무 요구사항(권한 분리, 상태 관리, CI, 보안 정책)에 맞춰 단계적으로 확장하는 것을 권장합니다.

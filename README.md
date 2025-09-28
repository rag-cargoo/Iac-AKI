# AWS, Ansible, Docker Swarm을 이용한 클러스터 구축 프로젝트

## 프로젝트 개요

Terraform으로 AWS 인프라를 프로비저닝하고, Ansible로 Docker Swarm 클러스터를 자동 구성한 뒤 Jupyter 노트북으로 운영·모니터링 스택을 확장하는 것이 목표입니다. 워크플로와 보안 수칙은 [Repository Guidelines](AGENTS.md)을 참고하세요.

---

## 빠른 시작 (실제 실행 경로)

1. **Terraform으로 인프라 생성**
   ```bash
   make tf-init               # 최초 1회
   make tf-plan
   make tf-apply              # 필요 시 -auto-approve 옵션 직접 추가
   ```
   *다른 환경을 사용하려면 `make TF_ENV_DIR=src/iac/terraform/envs/staging terraform-plan`처럼 지정합니다.*

2. **환경 변수 로드 및 Swarm 구성**
   ```bash
   make setup_env   # Terraform output 기반 SSH 구성과 환경 변수 로드
   make run         # setup_env 수행 + Ansible로 Docker Swarm 클러스터 구성
   ```

3. **클러스터 상태 점검**
   ```bash
   ssh swarm-manager
   docker node ls
   docker service ls
   ```

4. **추가 스택 배포 (옵션)**
   ```bash
   source run/common/setup_env.sh  # Docker context가 swarm-manager로 전환됨
   # 예: run/monitoring/README.md 따라 모니터링 스택 실행
   ```
   *필요 시 `ssh -N -L 9000:localhost:9000 -L 9090:localhost:9090 -L 3000:localhost:3000 swarm-manager`로 포트 포워딩을 설정해 웹 UI를 확인합니다.*
   *프롬프트 앞에 `[swarm-manager]`가 보이면 원격 매니저 컨텍스트가 활성화된 상태입니다.*

   터널링을 스크립트로 실행하려면:
   ```bash
   make tunnel   # setup_env + connect_service_tunnel.sh
   ```

---

## 실행 세부 정보 (참고용)

### 사전 준비
- Terraform, Ansible, AWS CLI 설치
- AWS 자격 증명 설정(IAM User Access Key/Secret Key)
- `terraform.tfvars`에 프로젝트/네트워크/인스턴스 정보 기입 (가이드: `src/iac/terraform/TFVARS_GUIDE.md`)

- 디렉터리 구조: `src/iac/terraform/modules/`(공용 모듈) · `envs/<env>/`(환경별 엔트리포인트) · `state/<env>/`(로컬 상태 저장소)
- `envs/production/backend.tf`는 `../../state/production/terraform.tfstate`를 기본 백엔드로 지정합니다.
- 실행 시 `terraform -chdir=...` 옵션을 사용하면 별도 `cd` 없이 일관되게 명령을 호출할 수 있습니다.

### Ansible 구성
- `make run`은 `run/common/setup_env.sh` 출력을 환경에 반영한 뒤 `ansible-playbook src/iac/ansible/playbooks/cluster.yml`을 실행합니다.
- 동적 인벤토리 플러그인: `src/iac/ansible/inventory_plugins/swarm.py`
- 기본 설정 파일: `src/iac/ansible/ansible.cfg`
- 개별 단계로 실행하려면 `make ansible` 또는 아래 명령을 사용할 수 있습니다.

  ```bash
  cd src/iac/ansible
  ANSIBLE_CONFIG=$(pwd)/ansible.cfg ansible-playbook playbooks/cluster.yml
  ```
- Nginx 샘플 서비스 테스트: `ansible-playbook roles/swarm_manager/tests/deploy_nginx.yml`

### SSH 및 Docker CLI 팁
- `run/common/setup_env.sh`는 Terraform output을 읽어 `~/.ssh/config`, `BASTION_PUBLIC_IP`, `MANAGER_PRIVATE_IPS`, `WORKER_PRIVATE_IPS`, `SSH_KEY_PATH` 등을 갱신합니다.
- 스크립트 실행 시 Docker 컨텍스트가 자동으로 `swarm-manager`로 전환됩니다. 로컬 Docker로 돌아가려면 `docker context use default`를 실행하세요.
- ssh-agent가 자동 시작되지 않으면 다음을 수동 실행하세요.
  ```bash
  eval "$(ssh-agent -s)"
  ssh-add "${SSH_KEY_PATH}"
  ```
- 직접 접속: `ssh swarm-manager`
- 터널링 스크립트: `run/common/connect_service_tunnel.sh`
- 프롬프트에 현재 컨텍스트 표시(`[swarm-manager]` 등)를 추가하고 싶다면 한 번만 아래를 실행하세요.
  ```bash
  run/common/install_swarm_prompt.sh
  source ~/.bashrc
  ```

-  실행형 문서는 `run/` 디렉터리에 단계별로 정리돼 있습니다. 예: [Monitoring Runbook](run/monitoring/README.md)

---

## 트러블슈팅 요약
- `terraform plan`이 변경 사항을 잡지 못하면 `terraform state list`, `terraform -chdir=... plan -refresh-only`로 드리프트를 확인하세요.
- SSH host key 충돌 시 `run/common/setup_env.sh`가 기존 키를 정리하므로 스크립트를 재실행합니다.
- Swarm 서비스 상태 확인: `docker service ps <service_name>`

---

*프로젝트의 구조나 실행 흐름이 바뀌면 이 문서와 `PROJECT_PLAN.md`를 함께 업데이트해 주세요.*

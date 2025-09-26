# AWS, Ansible, Docker Swarm을 이용한 클러스터 구축 프로젝트

## 프로젝트 개요

Terraform으로 AWS 인프라를 프로비저닝하고, Ansible로 Docker Swarm 클러스터를 자동 구성한 뒤 Jupyter 노트북으로 운영·모니터링 스택을 확장하는 것이 목표입니다. 워크플로와 보안 수칙은 [Repository Guidelines](AGENTS.md)을 참고하세요.

---

## 빠른 시작 (실제 실행 경로)

1. **Terraform으로 인프라 생성**
   ```bash
   terraform -chdir=01-infrastructure/terraform/envs/production init -reconfigure
   terraform -chdir=01-infrastructure/terraform/envs/production plan
   terraform -chdir=01-infrastructure/terraform/envs/production apply -auto-approve
   ```
   *변수 수정은 `01-infrastructure/terraform/envs/production/terraform.tfvars`에서 진행합니다.*

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
   source scripts/bin/setup_project_env.sh  # DOCKER_HOST=ssh://swarm-manager 자동 설정
   # 예: 04-runtime/notebooks/deploy-observability.ipynb 실행
   ```
   *필요 시 `ssh -N -L 9000:localhost:9000 -L 9090:localhost:9090 -L 3000:localhost:3000 swarm-manager`로 포트 포워딩을 설정해 웹 UI를 확인합니다.*
   *프롬프트 앞에 `[swarm]`이 보이면 `DOCKER_HOST`가 원격 매니저로 설정된 상태입니다.*

---

## 실행 세부 정보 (참고용)

### 사전 준비
- Terraform, Ansible, AWS CLI 설치
- AWS 자격 증명 설정(IAM User Access Key/Secret Key)
- `terraform.tfvars`에 프로젝트/네트워크/인스턴스 정보 기입 (가이드: `01-infrastructure/terraform/TFVARS_GUIDE.md`)

### Terraform 구성
- 디렉터리 구조: `modules/`(공용 모듈) · `envs/<env>/`(환경별 엔트리포인트) · `state/<env>/`(로컬 상태 저장소)
- `envs/production/backend.tf`는 `../../state/production/terraform.tfstate`를 기본 백엔드로 지정합니다.
- 실행 시 `terraform -chdir=...` 옵션을 사용하면 별도 `cd` 없이 일관되게 명령을 호출할 수 있습니다.

### Ansible 구성
- `make run`은 `scripts/bin/setup_project_env.sh` 출력을 환경에 반영한 뒤 `ansible-playbook 01-infrastructure/ansible/playbooks/cluster.yml`을 실행합니다.
- 동적 인벤토리 플러그인: `01-infrastructure/ansible/inventory_plugins/swarm.py`
- 기본 설정 파일: `01-infrastructure/ansible/ansible.cfg`
- 개별 단계로 실행하려면 `make ansible` 또는 아래 명령을 사용할 수 있습니다.

  ```bash
  cd 01-infrastructure/ansible
  ANSIBLE_CONFIG=$(pwd)/ansible.cfg ansible-playbook playbooks/cluster.yml
  ```
- Nginx 샘플 서비스 테스트: `ansible-playbook roles/swarm_manager/tests/deploy_nginx.yml`

### SSH 및 Docker CLI 팁
- `scripts/bin/setup_project_env.sh`는 Terraform output을 읽어 `~/.ssh/config`, `BASTION_PUBLIC_IP`, `MANAGER_PRIVATE_IPS`, `WORKER_PRIVATE_IPS`, `SSH_KEY_PATH` 등을 갱신합니다.
- 스크립트 실행 시 `DOCKER_HOST=ssh://swarm-manager`가 자동 설정됩니다. 로컬 Docker로 돌아가려면 `unset DOCKER_HOST`를 실행하세요.
- ssh-agent가 자동 시작되지 않으면 다음을 수동 실행하세요.
  ```bash
  eval "$(ssh-agent -s)"
  ssh-add "${SSH_KEY_PATH}"
  ```
- 직접 접속: `ssh swarm-manager`
- 터널링 스크립트: `./scripts/bin/connect_service_tunnel.sh`
- 프롬프트에 `[swarm]` 표시를 자동 추가하고 싶다면 한 번만 아래를 실행하세요.
  ```bash
  scripts/tools/install_swarm_prompt.sh
  source ~/.bashrc
  ```

### 노트북 기반 확장
- 운영/모니터링 (Prometheus · Grafana · Loki): [deploy-observability.ipynb](04-runtime/notebooks/deploy-observability.ipynb)
- 애플리케이션 배포 샘플(Spring Boot): [deploy-spring-app.ipynb](04-runtime/notebooks/deploy-spring-app.ipynb)
- 부하 테스트(k6): [k6-tests.ipynb](04-runtime/notebooks/k6-tests.ipynb)
  *모든 노트북은 첫 셀에서 `export DOCKER_HOST="ssh://swarm-manager"`를 보장해야 합니다.*

---

## 트러블슈팅 요약
- `terraform plan`이 변경 사항을 잡지 못하면 `terraform state list`, `terraform -chdir=... plan -refresh-only`로 드리프트를 확인하세요.
- SSH host key 충돌 시 `setup_project_env.sh`가 기존 키를 정리하므로 스크립트를 재실행합니다.
- Swarm 서비스 상태 확인: `docker service ps <service_name>`

---

*프로젝트의 구조나 실행 흐름이 바뀌면 이 문서와 `PROJECT_PLAN.md`를 함께 업데이트해 주세요.*

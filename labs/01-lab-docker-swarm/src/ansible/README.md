# Lab01 Ansible Layout

이 디렉터리는 Docker Swarm 실습을 위한 최소 Ansible 구성을 담고 있습니다.

## 디렉터리 구성
- `ansible.cfg` – 실습 전용 기본 설정 (동적 인벤토리, SSH 옵션 등)
- `inventory_plugins/swarm.py` – Terraform output 기반 Swarm 인벤토리 스크립트
- `playbooks/` – 실행 단위 플레이북 (`cluster.yml`, `bootstrap.yml`, `verify.yml`)
- `tasks/` – 재사용 태스크 묶음 (`docker_engine.yml`, `swarm_manager.yml`, `swarm_worker.yml`)
- `site.yml` – 클러스터 플레이북을 포함하는 단일 진입점

## 사용 방법
```bash
cd labs/01-lab-docker-swarm
make setup_env              # Terraform 출력 기반 환경 변수/SSH 구성
ANSIBLE_CONFIG=$(pwd)/src/ansible/ansible.cfg \
  ansible-playbook src/ansible/playbooks/cluster.yml
```

- Docker 엔진만 설치하려면 `playbooks/bootstrap.yml`
- 클러스터 상태를 점검하려면 `playbooks/verify.yml`
- 실습에서는 역할(`roles/`) 디렉터리를 사용하지 않고 Playbook + Tasks 조합만 유지합니다.

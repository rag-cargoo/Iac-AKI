# 프로젝트: AWS Ansible Docker Swarm

## 1. 프로젝트 목표
Terraform을 사용하여 AWS 인프라를 구축하고, Ansible을 사용하여 Docker Swarm 클러스터를 자동 구성 및 배포하는 것을 목표로 합니다.  
최종적으로 컨테이너화된 애플리케이션을 배포할 수 있는 Swarm 환경을 구축합니다.

---

## 2. 인프라 구성 (Terraform)
Terraform을 통해 다음 리소스를 생성했습니다:

- VPC, Subnet, Gateway 등 네트워크 환경
- EC2 인스턴스: Bastion, Manager, Worker (동적 확장 가능)
- 보안 그룹

Terraform output으로 필요한 정보(호스트 IP, SSH 키 경로 등)를 자동으로 추출하도록 구성했습니다.

---

## 3. 서버 구성 및 클러스터 구축 (Ansible)

### 3.1 환경 변수 및 SSH 설정
- `scripts/bin/setup_project_env.sh` 스크립트에서 Terraform output을 읽어 다음을 자동 설정:
  - `BASTION_PUBLIC_IP`, `MANAGER_PRIVATE_IP`, `WORKER_PRIVATE_IPS`, `SSH_KEY_PATH` 환경 변수
  - `~/.ssh/config` 자동 갱신 (Bastion, Manager, Worker 노드)
  - SSH agent 실행 및 키 추가
  - `known_hosts` 자동 등록
- SSH 접속 관련 트러블슈팅:
  - 매번 새 EC2 인스턴스가 생기면서 host key 충돌 발생 → `ssh-keygen -R <IP>` 자동 실행으로 해결
  - 핑거프린트 경고는 수동 확인 없이 `ssh-keyscan`으로 known_hosts 업데이트

### 3.2 Ansible 인벤토리
- Ansible은 `inventory_plugins/swarm.py` 스크립트를 호출하는 `inventory/production/swarm.yml`을 사용해 Terraform output 기반으로 호스트와 각 노드별 변수를 동적으로 불러옵니다
  - SSH 접속 정보는 `~/.ssh/config`에서 처리
  - 플레이북 실행 시 자동으로 최신 호스트 정보 반영
- ansible.cfg 설정:
  - `inventory = inventory/production/swarm.yml`
  - `host_key_checking = False`
  - `remote_user = ubuntu`
  - `collections_paths = /home/aki/.ansible/collections`
  - `[inventory] enable_plugins = script`

### 3.3 Docker 설치 및 Swarm 구성
- 모든 노드에 Docker Engine 설치
- Manager 노드 초기화 후 Worker 노드 조인
- 테스트용 Nginx 배포로 클러스터 동작 확인

---

## 4. 프로젝트 구조 (중요 스크립트)
- `setup_project_env.sh`: 환경 변수, SSH 설정, SSH agent, known_hosts 초기화
- `inventory_plugins/swarm.py`: Ansible 동적 인벤토리 제공 (필수)
- Makefile: `make run`으로 환경 초기화 + Ansible 플레이북 실행 자동화
- 삭제 가능/중복 스크립트:
  - `connect_manager.sh`, `run_env.sh` 등 (SSH 접속은 `ssh swarm-manager` 또는 Ansible에서 자동 처리 가능)

---

## 5. 트러블슈팅 및 해결 과정
1. SSH 접속 문제
   - 원인: 매번 새 EC2 인스턴스 생성 → known_hosts 충돌
   - 해결: `setup_project_env.sh`에서 기존 host key 자동 삭제 및 ssh-keyscan 등록
2. Ansible 인벤토리
   - 문제: 호스트 목록과 각 노드 변수 필요
   - 해결: `dynamic_inventory.py` 사용 → Terraform output 기반 동적 인벤토리 제공
3. Docker Swarm 초기화
   - Manager/Worker 조인 자동화
   - 환경 변수와 SSH config를 통해 Ansible이 원활히 접근 가능

---

## 6. 테스트 및 검증
- Nginx 서비스 3개 복제본 배포
- `docker service ps nginx_web` 명령으로 Manager 및 Worker에 컨테이너 정상 배포 확인

---

## 7. 향후 계획
- 모니터링 스택 설치 (Prometheus, Grafana)
- Swarm Manager HA 구성
- CI/CD 파이프라인 연동

---

- 💡 핵심 요약
- `inventory_plugins/swarm.py`는 필수 → Ansible 인벤토리 역할
- SSH 설정/초기화, host key 충돌, 핑거프린트 관련 트러블슈팅 내용 포함
- 불필요한 중복 스크립트는 제거 가능, Makefile과 `setup_project_env.sh` 중심으로 환경 구성

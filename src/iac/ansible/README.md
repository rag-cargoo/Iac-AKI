# Ansible Structure

이 디렉터리는 역할 기반 구조를 따르며, Docker Swarm 클러스터 구성을 자동화합니다.

## 주요 디렉터리
- `playbooks/` – 실행 단위 별 플레이북 (`cluster.yml`, `bootstrap.yml`, `verify.yml`)
- `roles/` – 역할별 태스크, 기본 변수, 테스트 (`docker_engine`, `swarm_manager`, `swarm_worker`)
- `inventory_plugins/` – 동적 인벤토리 플러그인(스크립트)

## 사용법
```bash
# 환경 변수 로드 (run/common/setup_env.sh 참고)
cd src/iac/ansible
ansible-playbook playbooks/cluster.yml

# 샘플 애플리케이션 배포 (옵션)
ansible-playbook playbooks/deploy_sample_app.yml
```

테스트 시에는 각 역할의 `tests/` 디렉터리에 있는 플레이북을 사용하거나 CI에서 `ansible-lint`, `molecule` 등을 연계하세요.

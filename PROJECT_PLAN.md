# 프로젝트: AWS · Ansible · Docker Swarm Labs

## 1. 프로젝트 목표
- AWS 상에 Docker Swarm 클러스터를 자동화하여 실습 기반으로 학습한다.
- Terraform으로 네트워크/보안/컴퓨트 리소스를 프로비저닝하고, Ansible로 Swarm을 구성한다.
- Runbook과 스크립트를 통해 SSH, 터널링, 모니터링 배포까지 한 번에 진행할 수 있는 워크플로를 정립한다.

## 2. 현재 진행 상태 (01-lab-docker-swarm)
- Terraform
  - `labs/01-lab-docker-swarm/src/terraform/envs/production/`에서 VPC, 보안 그룹, EC2(bastion/manager/worker) 생성.
  - 로컬 상태(`terraform.tfstate`)만 사용하며 실습 종료 시 삭제 예정.
- Ansible
  - `src/ansible/playbooks/cluster.yml` + `tasks/` 조합으로 Docker Engine 설치 → Swarm 초기화 → 워커 조인.
  - 동적 인벤토리: `src/ansible/inventory_plugins/swarm.py` (Terraform output 기반).
- Runbook
  - `labs/01-lab-docker-swarm/src/run/common/setup_env.sh`가 SSH config, known_hosts, Docker 컨텍스트를 자동 구성.
  - `labs/01-lab-docker-swarm/src/run/common/connect_service_tunnel.sh`로 PublishedPort 터널링 지원.
  - `labs/01-lab-docker-swarm/src/run/monitoring/README.md` + `labs/01-lab-docker-swarm/src/run/stacks/monitoring/stack.yml`로 Prometheus/Grafana 배포 가능.

## 3. 실행 흐름 요약
1. `make 01-lab-docker-swarm-init`
2. `make 01-lab-docker-swarm-run` (내부적으로 `tf-plan → tf-apply → ansible` 순으로 실행)
3. `ssh swarm-manager`에서 `docker node ls`, `docker service ls`
4. (옵션) `make 01-lab-docker-swarm-monitoring_deploy`
5. 종료 시 `make 01-lab-docker-swarm-monitoring_remove` 후 `make 01-lab-docker-swarm-tf-destroy`

루트에서는 `make 01-lab-docker-swarm-run`으로 전체 워크플로를, `make 01-lab-docker-swarm-tf-destroy`로 정리를 호출할 수 있다. 필요 시 `make 01-lab-docker-swarm-tf-plan` / `...-tf-apply`를 별도로 실행한다.

## 4. 트러블슈팅 기록
- SSH host key 충돌 → `setup_env.sh`에서 `ssh-keygen -R`, `ssh-keyscan` 자동화로 해결.
- Docker 컨텍스트 전환 → `setup_env.sh`에서 `docker context use swarm-manager` 처리.
- Terraform output 불일치 → `labs/01-lab-docker-swarm/src/run/common/diagnose_env.sh` 추가로 TF/Ansible 상태 점검 가능.

## 5. 향후 계획
- [ ] `docs/improvements/20250921-improvement-checklist.md` 항목 진행 (다중 매니저, SSH 강화 등)
- [ ] Terraform tfvars 샘플(.example) 정리 및 민감 정보 제거 자동화
- [ ] 모니터링 Runbook 확장 (`make monitoring_logs`, alerting 등)
- [ ] 추가 실습(`lab02-...`) 설계 시 템플릿 복제 및 루트 Makefile 타깃 확장

## 6. 문서 업데이트 필요 시 확인 항목
- `README.md`, `labs/01-lab-docker-swarm/README.md`
- `docs/INFRA_SERVICE_STRUCTURE.md`
- `AGENTS.md`
- `docs/improvements/` 체크리스트 및 진행 메모

실습 구조 전환 후에도 위 문서를 최신 상태로 유지하면 다음 Codex 세션에서 빠르게 맥락을 복구할 수 있다.

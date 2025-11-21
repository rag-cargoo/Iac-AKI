# Lab 01 – Docker Swarm on AWS

이 실습은 다음 단계를 다룹니다.

1. Terraform으로 VPC, 보안 그룹, EC2 인스턴스(매니저/워커/bastion)를 프로비저닝
2. Ansible로 Docker Engine 설치 및 Swarm 초기화/조인
3. Runbook 스크립트로 SSH 구성, Docker 컨텍스트 전환, 모니터링 스택 배포

## 실행 순서

```bash
cd labs/01-lab-docker-swarm

# Terraform
make tf-init
make tf-plan
make tf-apply

# Swarm 구성
make setup_env    # Terraform output 기반 SSH + Docker 컨텍스트 전환
make run          # ansible-playbook src/ansible/playbooks/cluster.yml

# 상태 확인 (예시)
ssh swarm-manager
docker node ls
docker service ls

# 모니터링 스택 (옵션)
make monitoring_deploy

# 정리
make monitoring_remove
make tf-destroy
```

## Terraform 참고
- 코드 위치: `src/terraform`
- 환경 디렉터리: `src/terraform/envs/production`
- 로컬 상태(`terraform.tfstate`)만 사용합니다. 실습 종료 후 불필요한 상태 파일을 삭제해 주세요.
- 변수 예시는 `src/terraform/TFVARS_GUIDE.md` 참고.
- 퍼블릭 Jenkins/Grafana 접근을 위해 ALB + Route 53 구성이 포함되었습니다. `terraform.tfvars`에 ACM 인증서 ARN(`certificate_arn`)과 Hosted Zone(`route53_zone_name`/`route53_record_names`)을 채워 넣으면 `*.goopang.me` 같은 도메인으로 HTTPS가 열립니다.
- ALB 설정은 `src/terraform/modules/load_balancer` 모듈로 묶여 있으며, Swarm 매니저의 8080 포트(기본 Jenkins 포트)를 타깃 그룹에 자동 등록합니다.

## Ansible 참고
- 진입점: `src/ansible/site.yml` 또는 `playbooks/cluster.yml`
- 동적 인벤토리: `src/ansible/inventory_plugins/swarm.py`
- 역할 대신 `tasks/` + `vars` 블록으로 가독성을 높였습니다.
- `make ansible` 타깃을 사용하면 Terraform 출력 없이도 플레이북만 재실행할 수 있습니다.

## Runbook & 스크립트
- `src/run/common/setup_env.sh` – SSH config, known_hosts, Docker 컨텍스트 자동화
- `src/run/common/connect_service_tunnel.sh` – 서비스 PublishedPort 기반 터널링 도우미
- `src/run/monitoring/README.md` – Prometheus + Grafana 배포 절차
- `src/run/stacks/` – Docker stack 정의 및 샘플 대시보드 저장소

필요한 인사이트나 시행착오를 `docs/` 하위에 기록해 두면 다음 세션에서 빠르게 맥락을 복구할 수 있습니다.

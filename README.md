# AWS · Ansible · Docker Swarm Labs

이 저장소는 Docker Swarm 클러스터 구축과 운영을 실습 단위로 학습하기 위한 워크스페이스입니다. 모든 실습은 `labs/` 아래에 격리돼 있으며, 각 실습은 자체 `Makefile`, `README.md`, `docs/`, `src/terraform|ansible|run` 디렉터리를 갖습니다.

현재 활성화된 실습은 다음과 같습니다.

- **01-lab-docker-swarm** – Terraform으로 AWS 인프라를 프로비저닝하고 Ansible로 Swarm 클러스터를 구성한 뒤 모니터링 스택을 배포
- **02-lab-s2svpn** – 온프레미스(고정 공인 IP)와 AWS VPC를 연결하는 Site-to-Site VPN 예제

---

## Quick Start

```bash
# 1) Terraform 초기화 (최초 1회)
make 01-lab-docker-swarm-init

# 2) 전체 워크플로 (plan → apply → Ansible)
make 01-lab-docker-swarm-run         # 적용 시 Terraform 프롬프트에서 확인

# 4) 상태 확인
ssh swarm-manager
docker node ls
docker service ls

# 5) 모니터링 스택 (옵션)
make 01-lab-docker-swarm-monitoring_deploy

# 6) 정리
make 01-lab-docker-swarm-tf-destroy

# 7) 기타 유틸 명령 (필요 시)
make 01-lab-docker-swarm-tunnel            # 서비스 PublishedPort 기반 SSH 터널 열기
make 01-lab-docker-swarm-monitoring_remove # 모니터링 스택 제거
make 01-lab-docker-swarm-tf-plan           # Terraform plan만 실행
make 01-lab-docker-swarm-setup_env         # 환경 변수 및 SSH 재구성만 실행
```

> Terraform 단계만 따로 보고 싶다면 `make 01-lab-docker-swarm-tf-plan` / `...-tf-apply`를 수동으로 실행하세요. 실습 디렉터리로 직접 들어가 `make tf-plan`처럼 호출할 수도 있습니다.

정리하거나 실습을 종료할 때는 `make 01-lab-docker-swarm-monitoring_remove`, `make 01-lab-docker-swarm-tf-destroy`를 차례대로 실행합니다.

---

## Lab 02 Quick Start (Site-to-Site VPN)

```bash
# 실습 디렉터리 이동
cd labs/02-lab-s2svpn

# 최초 1회 초기화
make tf-init

# 계획 및 적용
make tf-plan
make tf-apply

# 출력 값 확인
make 02-lab-s2svpn-tf-output

# 정리
make tf-destroy
```

`terraform.tfvars.example`를 참고해 `customer_gateway_ip`, `vpc_id`, `remote_ipv4_cidrs`, 필요 시 `route_table_ids` 등 환경별 값을 입력하면 다른 장소에서도 동일하게 적용할 수 있습니다.

로컬 strongSwan 게이트웨이를 자동으로 설치하려면 루트에서 다음 명령을 사용할 수 있습니다.

```bash
make 02-lab-s2svpn-strongswan
```

기본으로 sudo 비밀번호를 요청하며, 비밀번호가 필요 없으면 `make 02-lab-s2svpn-strongswan ANSIBLE_FLAGS=`처럼 덮어쓸 수 있습니다.
실행 전에 `sudo sysctl net.ipv4.ip_forward` 값이 `1`인지 확인하고, `0`이면 아래처럼 활성화·영구 적용해 두세요.
```bash
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-strongswan.conf >/dev/null
sudo sysctl --system
```
설치 후에는 `sudo systemctl status strongswan-starter`, `sudo ipsec statusall`로 서비스가 `active (running)`인지 확인하세요.
다운로드한 AWS 구성 파일은 `labs/02-lab-s2svpn/src/run/strongswan/download/`에 복사한 뒤 `make 02-lab-s2svpn-strongswan-generate-local`을 실행하면 `src/run/strongswan/templates/*.local`로 민감 값이 분리 저장됩니다. 결과만 미리 보고 싶으면 `CLONE_ONLY=true`를 붙여 사용하세요.
검토 후 `/etc`에 반영하려면 `make 02-lab-s2svpn-strongswan-install-local`을 실행하세요. 명령 안에서 자동으로 sudo를 요청하고, 기존 파일을 `.bak`으로 백업한 뒤 `# BEGIN/END aws-s2s-managed` 구간만 교체합니다.
상태 확인은 `make 02-lab-s2svpn-strongswan-verify`로 strongSwan을 재시작하고 `ipsec statusall` 결과를 확인하면 됩니다.

---

## Lab 01 Structure

```
labs/01-lab-docker-swarm/
├── Makefile                     # 실습 전용 명령 모음
├── README.md                    # 실습 안내 및 실행 순서
├── docs/                        # 실습 중 정리한 참고 자료
├── src/
│   ├── terraform/               # envs/<env>/, modules/, TFVARS 가이드 등
│   ├── ansible/                 # ansible.cfg, inventory 플러그인, playbooks/, tasks/
│   └── run/                     # setup_env.sh, SSH/터널 스크립트, monitoring runbook, stacks/
└── ...
```

- Terraform: `src/terraform/envs/production/`에서 네트워크 → 보안 → 컴퓨트 순으로 모듈을 호출합니다. 실습에서는 로컬 상태(`terraform.tfstate`)만 사용하며, 종료 후 파일을 정리해 주세요.
- Ansible: 역할 디렉터리를 제거하고 `playbooks/` + `tasks/` 구조로 간소화했습니다. 필요한 변수는 각 플레이북의 `vars` 블록에서 정의합니다.
- Runbook: `src/run/common/setup_env.sh`를 먼저 실행하면 SSH config, Docker 컨텍스트(`swarm-manager`)가 자동으로 맞춰집니다. 모니터링 스택은 `src/run/monitoring/README.md`와 `src/run/stacks/monitoring/stack.yml`을 참고하세요.

---

## 문서 & 진행 관리

- [docs/INFRA_SERVICE_STRUCTURE.md](docs/INFRA_SERVICE_STRUCTURE.md): 저장소 레이아웃과 실습 운영 지침.
- [AGENTS.md](AGENTS.md): Codex 에이전트가 따라야 할 규칙, 빌드/테스트 명령, 문서 정책.
- [PROJECT_PLAN.md](PROJECT_PLAN.md): 전체 로드맵과 우선순위, 진행 현황.
- `docs/improvements/`: 후속 개선 과제를 날짜별 체크리스트로 관리.

새 실습을 추가할 때는 `labs/<lab-id>/` 아래에 동일한 구조를 복제하고, 루트 `Makefile`에 해당 실습을 프록시하는 타깃을 추가하세요.

---

## 유의 사항

- 모든 Docker Swarm 관련 명령은 `labs/01-lab-docker-swarm` 디렉터리에서 실행한다고 가정합니다.
- Terraform, Ansible, AWS CLI, Docker CLI는 사전에 설치되어 있어야 합니다.
- SSH 키, Terraform tfstate, tfvars 등 민감 정보는 커밋하지 마세요. (기본 `.gitignore`에 포함되어 있습니다.)
- 구조 변경 또는 실습 추가 시 `README.md`, `AGENTS.md`, `PROJECT_PLAN.md`, 관련 runbook을 함께 업데이트해 주세요.

행복한 실습 되세요! 🚀

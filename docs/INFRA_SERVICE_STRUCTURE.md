# Repo Layout Blueprint

이 문서는 실습(lab) 단위로 AWS 인프라와 Docker Swarm 운영 자산을 관리할 때의 추천 디렉터리 구조와 운영 원칙을 설명합니다.

```
AWS-ANSIBLE-DockerSwarm/
├── docs/                            # 설계, 온보딩, 레퍼런스 문서
├── labs/
│   ├── 01-lab-docker-swarm/
│   └── 02-lab-s2svpn/
│       ├── Makefile                 # 실습 전용 명령(tf-apply, ansible, etc.)
│       ├── README.md                # 실습 안내 및 실행 순서
│       ├── docs/                    # 실습 중 정리한 참고 자료
│       └── src/
│           ├── terraform/           # envs/<env>/, modules/, TFVARS 가이드
│           ├── ansible/             # ansible.cfg, inventory_plugins/, playbooks/, tasks/
│           └── run/                 # setup_env.sh, 터널링/진단 스크립트, stacks/, runbook
└── ...
```

## 실습(Labs) 구조
- 모든 실습은 `labs/<lab-id>/` 디렉터리 아래에 격리합니다.
- 각 실습은 반드시 `src/terraform`, `src/ansible`, `src/run`, `docs/` 네 가지 하위 구조를 포함하도록 유지합니다.
- 실습 루트에는 `Makefile`과 `README.md`를 배치하여 실행 명령과 안내를 한눈에 확인할 수 있게 합니다.

```
labs/
├── 01-lab-docker-swarm/
│   ├── README.md
│   ├── Makefile
│   ├── docs/
│   │   ├── architecture.md
│   │   └── troubleshooting.md
│   └── src/
│       ├── terraform/
│       │   ├── envs/production/
│       │   ├── modules/
│       │   └── TFVARS_GUIDE.md
│       ├── ansible/
│       │   ├── ansible.cfg
│       │   ├── inventory_plugins/swarm.py
│       │   ├── playbooks/
│       │   └── tasks/
│       └── run/
│           ├── common/
│           │   ├── setup_env.sh
│           │   ├── connect_service_tunnel.sh
│           │   └── diagnose_env.sh
│           ├── monitoring/
│           │   └── README.md
│           └── stacks/
│               └── monitoring/
│                   └── stack.yml
└── 02-lab-s2svpn/
    ├── README.md
    ├── Makefile
    ├── docs/
    │   └── .gitkeep
    └── src/
        └── terraform/
            ├── envs/production/
            │   ├── main.tf
            │   ├── variables.tf
            │   └── terraform.tfvars.example
            └── modules/
                └── s2s_vpn/
                    ├── main.tf
                    ├── outputs.tf
                    └── variables.tf
```

### 운영 지침
- 실습 간 공유 리소스를 두지 말고, 필요한 파일은 각 실습 디렉터리 내부에 모두 배치합니다.
- 공통으로 참고할 만한 내용이 생기면 실습 `docs/`에 정리하고, 루트 `docs/`는 설계 철학이나 베스트 프랙티스를 중심으로 유지합니다.
- 실행 명령은 실습 `Makefile`에만 정의해 다른 실습과 충돌하지 않도록 합니다.
- 동일한 실습을 반복 사용할 계획이라면 `README.md`에 전제 조건, 실행 순서, 검증 방법을 상세히 기록해 온보딩 시간을 줄입니다.
- Terraform 상태 파일은 실습 디렉터리 내부의 로컬 상태(`src/terraform/terraform.tfstate` 또는 `.terraform/`)만 사용하고, 실습 종료 시 제거합니다.

### Terraform 상태 관리 (Labs)
- 원격 백엔드(S3, DynamoDB 등)를 구성하지 않고 로컬 상태만 사용합니다.
- `src/terraform/terraform.tfstate`와 `src/terraform/.terraform/`는 `.gitignore`에 포함합니다.
- 실습 이전 버전에서 사용하던 상태 디렉터리가 남아 있다면 백업 후 제거하여 충돌을 방지합니다.
- 여러 실습을 동시에 진행하더라도 각 실습 경로가 다르므로 Terraform workspace를 분리할 필요가 없습니다.

### 루트 Makefile 및 운영 문서
- 루트 `Makefile`은 실습별 `Makefile`을 프록시합니다. 예:
  ```Makefile
  01-lab-docker-swarm-run:
  	$(MAKE) -C labs/01-lab-docker-swarm workflow
  01-lab-docker-swarm-%:
  	$(MAKE) -C labs/01-lab-docker-swarm $*
  ```
- 루트 `README.md`는 실습 목록과 구조를 요약하고, 각 실습 `README.md`로 이동하는 링크를 제공합니다.
- `AGENTS.md`에는 현재 진행 중인 실습, 브랜치, 다음 액션, 중요 규칙을 최신 상태로 유지합니다.
- `PROJECT_PLAN.md`는 전체 로드맵과 실습 우선순위를 표나 체크리스트로 관리합니다.

### Ansible 구조 (Labs)
- 학습 목적이라면 역할(roles)을 사용하지 않고, 필요한 태스크만 `playbooks/cluster.yml`, `tasks/docker_engine.yml` 등으로 구성합니다.
- 반복 사용이 필요한 태스크나 변수가 없다면 `defaults/`, `vars/`, `tests/` 디렉터리를 만들지 않습니다.
- 태스크가 길어질 경우 `tasks/setup.yml`, `tasks/deploy.yml`처럼 `import_tasks`로만 분리하고, 파일 수를 늘리지 않도록 합니다.
- 실습별 요구 사항이 다르면 `playbooks/`에 여러 플레이북을 두되, 이름은 목적별(`cluster.yml`, `monitoring.yml`, `cleanup.yml`)로 유지합니다.

> ※ CI/CD 정의는 조직 표준에 맞춰 `.github/`, `ci/`, `pipelines/` 등의 전용 디렉터리에 분리해 관리하세요.

## 디렉터리별 설명 (실습 중심)
- **docs/**: 리포지토리 구조, 실무 가이드, 트러블슈팅 노트를 포함한 문서 허브입니다.
- **labs/**: 실습별 코드와 문서를 보관합니다. 각 실습은 독립적으로 Terraform/Ansible/Runbook을 실행할 수 있습니다.
- **labs/<lab-id>/src/terraform/**: 네트워크 → 보안 → 컴퓨트 순으로 모듈을 호출합니다. 로컬 상태만 사용합니다.
- **labs/<lab-id>/src/ansible/**: ansible.cfg, 동적 인벤토리, 플레이북, 태스크를 관리합니다.
- **labs/<lab-id>/src/run/**: 실행(runbook)과 공용 스크립트를 모아 둡니다. SSH 초기화, 터널링, 모니터링 스택 배포 등이 포함됩니다.

## 운영 시 고려 사항
1. **권한 분리**: 실습별 디렉터리 수준에서 접근 권한을 제어하면 됩니다. 공통 코드가 없으므로 충돌 위험이 낮습니다.
2. **CI/CD 파이프라인**: 인프라(Terraform)와 애플리케이션(Ansible/docker stack)을 분리된 워크플로로 테스트합니다.
3. **관찰성과 백업**: `src/run/stacks/`를 통해 필요한 스택을 Swarm 위에 반복 배포할 수 있도록 템플릿과 예제를 제공합니다.
4. **문서화**: 구조 변경 시 `docs/INFRA_SERVICE_STRUCTURE.md`, `docs/REAL_WORLD_STRUCTURE.md`, `AGENTS.md`, 실습 `README.md`를 함께 업데이트합니다.

## 리포지토리 운영 패턴 비교
- **단일 리포 (Monorepo)**: 실습/운영 스크립트를 한곳에서 관리해 온보딩이 빠르지만, 접근 통제와 승인 절차가 복잡해질 수 있습니다.
- **실습 분리형 (Current)**: 실습 단위로 완전히 격리하여 실험과 학습이 용이합니다. 실무 배포용 코드와 분리해 다룰 수 있습니다.
- **혼합형**: 인프라는 중앙 저장소, 실습은 별도 저장소에 보관하는 방식도 고려할 수 있습니다.

## 실습 전환 체크리스트
- [ ] 실습 `README.md`에 실행 순서, 전제 조건, 정리 방법을 명시
- [ ] `labs/<lab-id>/Makefile`에서 Terraform/Ansible/Runbook 명령 확인
- [ ] Terraform tfstate/tfvars가 커밋되지 않는지 확인 (`.gitignore` 재점검)
- [ ] `labs/<lab-id>/src/run/common/setup_env.sh` 경로와 Terraform env 디렉터리가 일치하는지 확인
- [ ] 구조 변경 사항을 `PROJECT_PLAN.md`와 루트 `README.md`에 반영
- [ ] 다음 세션을 위한 메모를 `docs/improvements/` 또는 실습 `docs/`에 남김

> 구조를 변경할 때마다 이 체크리스트를 업데이트하고, 완료된 항목은 `x`로 표시하세요.

# Repo Layout Blueprint

이 문서는 인프라(IaC)와 서비스 애플리케이션을 하나의 저장소에서 관리할 때 추천하는 디렉터리 구조와 운영 원칙을 정리합니다. 필요한 영역부터 점진적으로 채워 넣으면서 팀의 워크플로에 맞게 확장하세요.

```
AWS-ANSIBLE-DockerSwarm/
├── docs/                            # 설계, 온보딩, 레퍼런스 문서
├── src/iac/                         # Terraform + Ansible 기반 IaC
│   ├── terraform/
│   │   ├── modules/                  # network, security, compute 등 재사용 모듈
│   │   └── envs/<environment>/       # production, staging 등 환경별 진입점
│   └── ansible/
│       ├── roles/                    # docker_engine, swarm_manager, swarm_worker
│       ├── playbooks/
│       └── inventory_plugins/
├── src/stacks/                     # 관찰성·로깅·성능 등 플랫폼 운영 자산
│   ├── monitoring/
│   ├── logging/
│   └── performance/
├── src/stacks/app-services/         # 서비스별 배포 매니페스트와 예제 스택
│   └── sample-spring-app/
├── run/                             # 실행(runbook) 및 공용 스크립트
│   ├── common/                      # setup_env.sh, connect_service_tunnel.sh 등
│   └── monitoring/                  # 스택별 실행 절차 (README 등)
└── env-config/ (optional)            # 환경 변수 템플릿, Vault 매핑, Feature Flag 등
```

> ※ CI/CD 정의는 조직 표준에 맞춰 `.github/`, `ci/`, `pipelines/` 등의 전용 디렉터리에 분리해 관리하세요.

## 디렉터리별 설명
- **docs/**: 리포지토리 구조, 실무 가이드, 트러블슈팅 노트를 포함한 문서 허브입니다.
- **src/iac/**: Terraform과 Ansible을 통해 VPC, EC2, 보안 그룹, Swarm 클러스터를 코드로 관리합니다. 네트워크 → 보안 → 컴퓨트 순으로 모듈을 호출하고, Ansible은 역할 기반 구조를 유지합니다.
- **src/stacks/**: Prometheus/Grafana, Loki/Promtail, k6 등 관찰성과 운영 도구를 저장합니다. Swarm 배포용 스택 정의와 추가 자동화 스크립트가 포함됩니다.
- **src/stacks/app-services/**: 서비스별 스택 정의(`stack.yml`), 배포 노트북, 공통 라이브러리 등을 모읍니다. 샘플 애플리케이션을 기준으로 신규 서비스를 온보딩하세요.
- **run/**: runbook과 공용 스크립트를 모아 실행 단계를 문서화합니다. `run/common/`에는 환경 설정, 터널링, 진단 스크립트를, `run/<service>/`에는 서비스별 실행 절차를 정리합니다.
- **env-config/** (선택): 환경별 `.env` 템플릿과 시크릿 매핑 정보를 버전 관리합니다. AWS SSM, Secrets Manager, Vault 연동 가이드를 함께 문서화하세요.

## 운영 시 고려 사항
1. **권한 분리**: `src/iac/` 변경은 제한된 승인 절차를 거치고, `src/stacks/app-services/`는 서비스 팀이 자율적으로 관리할 수 있도록 정책을 구분합니다.
2. **CI/CD 파이프라인**: 인프라는 Terraform Plan → 승인 → Apply, 애플리케이션은 Build → Test → Deploy 파이프라인을 별도로 구성합니다.
3. **관찰성과 백업**: 공통 운영 스택(`src/stacks/`)을 Swarm 또는 Kubernetes에서 재사용 가능하도록 템플릿과 예제 플레이북을 제공합니다.
4. **문서화**: 구조 변경 시 `docs/INFRA_SERVICE_STRUCTURE.md`, `docs/REAL_WORLD_STRUCTURE.md`, `AGENTS.md`를 최신 상태로 유지해 신규 기여자가 빠르게 온보딩할 수 있도록 합니다.

## 리포지토리 운영 패턴 비교
실무에서는 조직 규모와 협업 방식에 따라 여러 저장소 모델이 혼용됩니다. 구조를 설계하기 전에 다음 패턴들의 장단점을 고려하세요.

### 1. 단일 리포 (Monorepo)
- **구성**: 인프라(IaC), 서비스 소스, 공통 스크립트를 동일 저장소에 포함합니다.
- **장점**: 프로젝트 자산을 한눈에 확인하고 공통 코드/문서를 쉽게 재사용할 수 있습니다.
- **단점**: 권한 분리, 승인 프로세스, CI/CD 파이프라인이 복잡해질 수 있습니다. 대규모 팀에서는 머지 충돌이 잦습니다.
- **권장 사례**: 소규모 팀, 초기 MVP, 인프라와 서비스가 동일한 릴리스 주기를 갖는 경우.

### 2. 다중 리포 (Multi-Repo)
- **구성**: 인프라 전용 리포, 서비스별 리포, 공통 플랫폼 리포 등으로 분리합니다.
- **장점**: 팀/역할별 책임을 명확히 분리하고 서비스별 배포 파이프라인을 독립적으로 운영할 수 있습니다.
- **단점**: 공통 코드와 문서를 여러 리포에서 중복 관리해야 하며 동기화 비용이 발생합니다.
- **권장 사례**: 여러 팀이 협업하거나 서비스별 스택/릴리스 주기가 크게 다른 조직.

### 3. 혼합형
- **구성**: 인프라는 전용 리포에서 중앙 관리하고, 서비스는 서비스별 리포로 분리합니다. 공통 라이브러리/스크립트/CI 템플릿은 별도 리포 또는 패키지로 관리합니다.
- **장점**: 인프라 통제와 서비스 자율성을 동시에 확보합니다. 공통 자산을 버전 관리하면서 여러 리포에서 재사용할 수 있습니다.
- **단점**: 리포 간 의존성 추적이 필요하며 변경 파급을 관리하려면 문서화가 필수입니다.
- **권장 사례**: 플랫폼팀이 인프라를 관리하고 서비스팀이 독립적으로 배포하는 조직, GitOps/Argo CD/Spinnaker 등과 연계된 환경.

### 실무에서 자주 보이는 리포 분류 예시
- `infra-aws/`, `infra-gcp/`, `infra-monitoring/`: 클라우드별 IaC, 모니터링·보안 인프라
- `service-foo/`, `service-bar/`: 서비스별 애플리케이션 코드와 배포 정의
- `platform-observability/`: Grafana 대시보드 JSON, Alert 규칙, Runbook
- `devops-pipelines/`: Jenkinsfile, GitHub Actions, Argo CD 애플리케이션 정의 등
- `shared-libs/`: 회사 공통 SDK, 파이썬/노드 패키지, CICD 스텝 공유 코드

필요한 저장소만 선택하되 `docs/`에 리포 간 관계와 책임 범위를 문서화하여 거버넌스를 명확히 하세요.

## 현재 프로젝트 전환 체크리스트
> 아래 단계는 현 리포지토리를 상기 구조로 확장할 때 참고할 수 있는 TODO 목록입니다. 완료한 항목은 체크 표시(✓)로 업데이트해 진행 상황을 관리하세요.

- [ ] `docs/` 문서를 최신 구조에 맞춰 정비하고 온보딩 자료를 통합
- [ ] `src/iac/terraform/` 모듈을 네트워크 → 보안 → 컴퓨트 순으로 호출하도록 검증
- [ ] `src/iac/ansible/` 플레이북과 `run/common/` 실행 스크립트 경로를 일치시킵니다.
- [ ] `src/stacks/`에 모니터링·로깅·성능 스택을 분리 배치하고 Swarm 배포 가이드를 추가
- [ ] `src/stacks/app-services/`에 서비스별 스택/노트북을 정리하고 배포 워크플로를 문서화
- [ ] `run/<service>/README.md`와 같은 실행 가이드에서 `run/common/setup_env.sh` 호출 여부를 검증
- [ ] 환경별 변수/시크릿 템플릿을 `env-config/` 또는 Parameter Store/Vault로 이동
- [ ] CI/CD 파이프라인 정의를 `.github/`(또는 `ci/`)로 이동하고 IaC·서비스 파이프라인을 분리
- [ ] Terraform에서 AWS Network Firewall/Firewall Manager 토글을 모듈 변수(`firewall_enabled`)로 추상화

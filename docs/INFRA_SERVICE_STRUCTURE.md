# Repo Layout Blueprint

아래 구조는 인프라(IaC)와 서비스 애플리케이션을 한 저장소 안에서 명확히 분리해 운영하기 위한 예시입니다. 실제로 디렉터리를 모두 만들어두기보다는, 팀에서 필요한 부분부터 단계적으로 채워 넣으며 관리하면 됩니다.

```
AWS-ANSIBLE-DockerSwarm/
├── infra/                              # 인프라 전용 영역
│   ├── terraform/                      # 네트워크·컴퓨트·보안 모듈, 환경별 디렉터리 (envs/prod 등)
│   │   ├── modules/                    # reusable module (network, security, compute, monitoring 등)
│   │   └── envs/
│   │       ├── production/
│   │       └── staging/
│   ├── ansible/                        # 서버/클러스터 프로비저닝 및 운영 자동화
│   │   ├── roles/                      # docker_engine, swarm_manager, logging_agent 등 역할별 디렉터리
│   │   ├── playbooks/
│   │   └── inventory/
│   ├── monitoring/                     # Prometheus/Grafana/ELK 등의 IaC, Helm 차트, Ansible 역할 등
│   ├── cicd/                           # Jenkins/GitHub Actions runner 설정, pipeline-as-code
│   ├── logging/                        # 중앙 로그 시스템 (ELK, Loki 등) 배포 및 설정 코드
│   ├── backup/                         # 스냅샷, 데이터 백업 정책, 스크립트, Terraform 모듈
│   ├── security/                       # IAM, KMS, 보안 스캐닝, 정책 템플릿
│   └── docs/                           # 인프라 운영 문서, Runbook, 변경 기록
├── services/                           # 애플리케이션 코드 영역
│   ├── service-a/
│   │   ├── src/
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   └── deploy/                     # 서비스 전용 배포 스크립트/템플릿(Helm chart, Ansible role 등)
│   ├── service-b/
│   └── shared-libraries/               # 공통 라이브러리 또는 SDK
├── platform/                           # 공통 운영 컴포넌트(옵션)
│   ├── observability/                  # SLO/SLA, 알림 템플릿, 대시보드 JSON 등
│   ├── scripts/                        # 운영 자동화 스크립트(bin, tools, lib 등 세분화)
│   └── makefiles/                      # 공용 Make/Task 정의
├── env-config/                         # 환경 변수, 설정 템플릿, Vault/Parameter Store 매핑 정보
├── docs/                               # 상위 문서(구조 가이드, 온보딩, 아키텍처 개요 등)
└── .github/ or ci/                     # CI/CD 파이프라인 정의 파일 (GitHub Actions, GitLab CI 등)
```

> ※ 여러 리포로 쪼갤 경우에는 아래 "실무에서 자주 보이는 리포 분류 예시" 섹션의 명명 규칙을 참고해 별도 저장소로 분리해 운영하세요.

## 디렉터리별 설명
- **infra/**: VPC, EC2, 보안 그룹, 모니터링 스택, CI/CD 인프라 등을 코드로 관리합니다. Terraform과 Ansible을 분리해 모듈화해 두면 환경 확장 및 DR 구성 시 유용합니다.
- **services/**: 실제 애플리케이션 소스 코드, 테스트, 배포 매니페스트를 보관합니다. 서비스별로 독립적인 CI 파이프라인과 배포 전략을 가질 수 있습니다.
- **platform/**: 인프라와 서비스 사이를 잇는 공통 운영 자산(대시보드, 운영 스크립트, 표준 Makefile 등)을 저장합니다.
- **env-config/**: 환경별 설정값(.env 템플릿, Vault/Secrets Manager 키 매핑, Feature Flag 정의 등)을 문서화하거나 템플릿화합니다.
- **docs/**: 저장소 전반에 대한 가이드, 온보딩 문서, 아키텍처 다이어그램을 정리합니다.
- **.github/** 또는 **ci/**: 저장소 레벨의 CI/CD 파이프라인 정의 파일을 모아둡니다.

## 운영 시 고려 사항
1. **권한 분리**: 인프라 변경은 제한된 승인 절차를 거치고, 서비스 코드는 팀별로 자율성을 보장합니다.
2. **CI/CD 파이프라인**: `infra/`는 Terraform Plan → 승인 → Apply, `services/`는 Build → Test → Deploy 순으로 별도 파이프라인을 구성하면 안정적입니다.
3. **백업/로그/모니터링**: 인프라 계층에서 공용으로 제공하면서도 서비스 팀이 쉽게 연동할 수 있도록 템플릿과 예제 플레이북을 제공하세요.
4. **문서화**: 구조 변경 시 `docs/INFRA_SERVICE_STRUCTURE.md`와 같은 문서를 최신 상태로 유지하여 신규 기여자가 빠르게 온보딩할 수 있게 합니다.

필요한 부분부터 구조를 도입한 다음, 점진적으로 세부 디렉터리를 채워 나가면 실무에서도 유지보수하기 수월한 프로젝트 형태를 갖출 수 있습니다.


## 리포지토리 운영 패턴 비교
실무에서는 조직 규모와 협업 방식에 따라 여러 저장소 모델이 혼용됩니다. 구조를 설계하기 전에 다음 패턴들의 장단점을 고려하세요.

### 1. 단일 리포 (Monorepo)
- **구성**: 인프라(IaC), 서비스 소스, 공통 스크립트를 한 저장소에 모두 포함
- **장점**: 프로젝트 전반을 한눈에 확인 가능, 공통 코드/문서 재사용이 쉽고 온보딩 속도가 빠름
- **단점**: 권한 분리와 승인 프로세스를 세밀하게 제어하기 어렵고, CI/CD 파이프라인이 복잡해짐. 대규모 팀에서는 머지 충돌이 잦을 수 있음
- **권장 사례**: 소규모 팀, 초기 MVP 또는 마이크로서비스 수가 적을 때. 인프라 변경과 서비스 배포가 한 팀에서 동시에 이뤄지는 경우

### 2. 다중 리포 (Multi-Repo)
- **구성**: 인프라 전용 리포, 서비스별 리포, 공통 플랫폼 리포 등으로 분리
- **장점**: 팀/역할별로 권한과 책임을 명확히 분리하고, 서비스별 배포 파이프라인을 독립적으로 운영 가능. 릴리스 주기가 서로 다른 시스템을 관리하기 수월함
- **단점**: 공통 코드나 스크립트 공유가 불편하고, 각 리포에서 문서화와 규칙을 중복 관리해야 함
- **권장 사례**: 여러 팀이 협업하거나, 서비스별 스택/릴리스 주기가 크게 다를 때. 인프라 변경 승인 절차가 엄격한 조직

### 3. 혼합형
- **구성**: 인프라는 전용 리포에 두고, 서비스는 서비스별 리포로 분리. 공통 라이브러리/스크립트/CI 템플릿은 별도 리포 또는 패키지로 관리
- **장점**: 인프라 통제와 서비스 자율성을 동시에 확보. 공통 자산을 버전 관리하면서 여러 리포에서 재사용 가능
- **단점**: 리포 간 의존성 관리가 필요하며, 변경 파급을 추적하려면 문서화가 필수적
- **권장 사례**: DevOps/플랫폼팀이 인프라를 중앙에서 관리하고, 서비스 팀이 독립적으로 배포하는 조직. GitOps, Argo CD, Spinnaker 등과 연계해 환경별 배포를 자동화할 때

### 실무에서 자주 보이는 리포 분류 예시
- `infra-aws/`, `infra-gcp/`, `infra-monitoring/`: 클라우드별 IaC, 모니터링 등
- `service-foo/`, `service-bar/`: 서비스별 애플리케이션 코드
- `platform-observability/`: Grafana 대시보드 JSON, Alert 규칙, Runbook
- `devops-pipelines/`: Jenkinsfile, GitHub Actions, Argo CD 애플리케이션 정의 등
- `shared-libs/`: 회사 공통 SDK, 파이썬/노드 패키지, CICD 스텝 공유 코드

필요한 저장소만 선택해 운영하면서도 문서(`docs/`)에 리포 간 관계와 책임 범위를 명확히 기록하는 것이 중요합니다.

## 현재 프로젝트 전환 체크리스트
> 아래 단계는 현 리포지토리를 위 구조로 확장할 때 참고할 수 있는 TODO 목록입니다. 완료한 항목은 체크 표시(✓)로 업데이트해 진행 상황을 관리하세요.

- [ ] 최상위에 `infra/`, `services/`, `platform/`, `env-config/` 디렉터리 스켈레톤 생성
- [ ] 기존 `Iac/` 내용을 `infra/terraform/` 및 `infra/ansible/`로 이동하고 경로/스크립트 업데이트
- [ ] 모니터링, 로깅, 백업 등 추가 인프라 스택을 `infra/monitoring/`, `infra/logging/` 등에 분리 배치
- [ ] 서비스 애플리케이션 코드를 `services/<service-name>/` 구조에 맞춰 분리하고 배포 매니페스트 정리
- [ ] 공통 스크립트와 자동화 도구를 `platform/scripts/` 혹은 패키지 리포로 이동
- [ ] 환경별 설정 템플릿과 시크릿 매핑을 `env-config/`에 정리하고 문서화
- [ ] CI/CD 파이프라인 정의를 `.github/`(또는 `ci/`)로 이동하고 인프라/서비스 파이프라인을 분리
- [ ] `docs/INFRA_SERVICE_STRUCTURE.md`와 `AGENTS.md`에 구조 변경 내역을 반영하고 온보딩 가이드 갱신
- [ ] Terraform에서 AWS Network Firewall + Firewall Manager 같은 고급 방화벽 정책을 토글(`firewall_enabled` 변수)로 끄고 켤 수 있도록 설계 보완

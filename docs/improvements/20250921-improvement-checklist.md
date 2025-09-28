# Infrastructure & Automation 개선 체크리스트

최근 코드 리뷰에서 확인된 문제점과 개선 항목을 단계별 체크박스로 정리했습니다. 각 항목을 해결할 때마다 `x`로 표시해 진행 상황을 추적하세요.

> 파일 네이밍 규칙: `YYYYMMDD-title.md` 형태로 작성하며, 모든 개선 과제를 완료하면 파일명을 `YYYYMMDD-title-completed.md`로 변경해 마무리 상태를 명확히 표시합니다.

## 1. 다중 Swarm 매니저 지원 정비
- [ ] `run/common/setup_env.sh`에서 Terraform 출력 중 `manager_private_ips` 전체를 환경 변수로 노출 (`MANAGER_PRIVATE_IPS=*`)하고, 첫 번째 값만 고정으로 사용하는 로직 제거
- [ ] `src/iac/ansible/inventory_plugins/swarm.py`를 다중 매니저를 처리하도록 업데이트 (`swarm_manager` 그룹에 모든 매니저 호스트 추가, proxy 설정 포함)
- [ ] `src/iac/ansible/playbooks/cluster.yml`와 `roles/swarm_worker/`가 매니저 그룹에서 조인 토큰을 읽도록 수정 (첫 번째 호스트 의존성 제거)
- [ ] 매니저 HA 시나리오에 대한 테스트 플레이북/문서 추가 (`verify.yml` 확장 또는 별도 테스트)

## 2. SSH known_hosts 등록 지연 문제 해결
- [ ] `run/common/setup_env.sh`에서 사설 IP를 직접 `ssh-keyscan`하는 구간 제거 또는 bastion을 통한 프록시 스캔으로 교체
- [ ] 대체 접근 방식 문서화 (`README.md` 또는 `AGENTS.md`에 실행 시 보안 옵션 설명)
- [ ] 수정 후 SSH 설정/known_hosts 업데이트 흐름 재검증 (테스트 로그 첨부)

## 3. Terraform 상태 파일 보안 강화
- [ ] 루트 경로에 남아 있는 `src/iac/terraform/terraform.tfstate`/`terraform.tfvars` 제거하고, 필요 시 샘플 파일은 `.example` 확장자로 교체
- [ ] `.gitignore`에 state 파일 경로가 누락된 부분이 있는지 재확인 (필요 시 `state/` 디렉터리 추가)
- [ ] 실무 사용 가이드(`docs/REAL_WORLD_STRUCTURE.md` 등)에 원격 백엔드(S3/DynamoDB) 설정 권장 문구 보강
- [ ] 상태 파일/민감 정보 커밋을 방지하기 위한 CI 점검 항목 추가 (예: pre-commit, GitHub Actions)


## 진행 메모
- (예시) 2025-09-21 – 다중 매니저 지원 개선 우선순위 확인 필요. Terraform 상태/키 파일 정리 작업은 아직 미착수.

> 참고: 각 단계 완료 후 PR 설명이나 문서에 체크 상태를 반영하고, 위 진행 메모 섹션에 특이 사항이나 남은 작업 맥락을 간단히 남겨 두면 재시작 시 빠르게 파악할 수 있습니다.

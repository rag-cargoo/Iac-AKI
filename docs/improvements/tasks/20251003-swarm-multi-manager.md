# Docker Swarm 다중 매니저 지원 과제

## 배경
- `run/common/setup_env.sh`와 `swarm.py`가 첫 번째 매니저만 대상으로 동작하여 HA 구성이 불가능.
- `docs/improvements/20250921-improvement-checklist.md` 1번 항목이 미완료 상태.

## 목표
1. Terraform 출력과 환경 스크립트에서 모든 매니저 IP를 노출한다.
2. Ansible 인벤토리/플레이북/역할이 다중 매니저를 인식하도록 리팩토링한다.
3. HA 시나리오 테스트/문서를 추가해 재발 방지한다.

## 세부 작업
1. **Environment 스크립트**
   - `run/common/setup_env.sh`에서 `manager_private_ips` 전체를 `MANAGER_PRIVATE_IPS`로 export.
   - Docker 컨텍스트 검증 로직을 모든 매니저와 워커 IP 목록과 비교하도록 수정.
2. **Ansible 인벤토리 플러그인**
   - `src/iac/ansible/inventory_plugins/swarm.py`가 매니저 리스트를 순회하여 `swarm_manager` 그룹에 모두 추가하도록 변경.
   - 프록시/SSH 옵션이 각 매니저에 동일하게 적용되는지 확인.
3. **플레이북/역할**
   - `cluster.yml`에서 매니저 그룹을 대상으로 초기화/토큰 배포 과정을 재검토.
   - `roles/swarm_worker`가 조인 토큰과 remote addrs를 첫 매니저에 의존하지 않도록 수정.
   - 필요 시 새로운 매니저 추가/승격(playbook) 작성.
4. **테스트/문서**
   - `playbooks/verify.yml` 또는 신규 테스트 플레이북에서 다중 매니저 상태를 검증 (`docker node ls`, `docker node promote` 등).
   - HA 운영 절차를 `docs/` 하위(예: `docs/runbooks/swarm-ha.md`)에 정리.
5. **런북 업데이트**
   - `run/common` 스크립트와 도커 컨텍스트 사용법 문서(`AGENTS.md`, `docs/INFRA_SERVICE_STRUCTURE.md`) 갱신.

## 검증 체크리스트
- `MANAGER_PRIVATE_IPS` 환경 변수가 쉘에서 배열/공백 구분 문자열로 노출되는지 확인.
- `ansible-inventory --list` 출력에 모든 매니저 노드가 포함되는지 확인.
- `docker node ls`에서 매니저 노드가 기대 수만큼 `Leader/Reachable` 상태인지 검증.
- HA 테스트 플레이북 실행 로그를 문서에 첨부.

## 참고 문서
- `docs/improvements/20250921-improvement-checklist.md`
- `docs/INFRA_SERVICE_STRUCTURE.md`

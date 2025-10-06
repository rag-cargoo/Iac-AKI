# SSH Host Key 검증 강화 과제

## 배경
- 현재 스크립트는 `StrictHostKeyChecking=no`, `UserKnownHostsFile=/dev/null` 설정에 의존해 자동화 편의성을 확보했지만 보안 정책에 부합하지 않음.
- `run/common/setup_env.sh`가 사설 IP를 직접 `ssh-keyscan`하여 bastion을 거치지 않으며, bastion 기반 스캔 요구사항이 미이행 상태.

## 목표
1. bastion을 통해 호스트 키를 수집/검증하는 안전한 플로우로 전환.
2. SSH/Docker/Ansible 공통 설정에서 `StrictHostKeyChecking`을 다시 활성화한다.
3. 실행 문서에 보안 강화 절차와 운영 팁을 명확히 기술한다.

## 세부 작업
1. **키 수집 방식 변경**
   - `run/common/setup_env.sh`에서 `ssh-keyscan` 호출을 bastion에서 실행하도록 변경 (`ssh -J bastion-host ssh-keyscan ...`).
   - 로컬 known_hosts 파일을 관리하되 이전 키 제거 로직을 유지.
2. **SSH 설정 재구성**
   - SSH config 블록에서 `StrictHostKeyChecking no`를 제거하거나 선택적으로 토글할 수 있는 환경 변수 도입.
   - `UserKnownHostsFile`를 기본 경로로 복귀시키고 필요 시 별도 캐시 파일 사용.
3. **Docker 컨텍스트 대응**
   - Docker CLI가 SSH config 변화를 인지하도록 `docker context update` 흐름 수정.
   - 실패 시 재시도 및 경고 메시지를 명확히 한다.
4. **Ansible 설정 조정**
   - `ansible.cfg`의 `host_key_checking`을 True로 되돌리고, 첫 실행 시 필요한 안내를 플레이북/문서에 추가.
5. **문서화**
   - `docs/troubleshooting/ssh_error_known_hosts.md`에 bastion 기반 키 수집 절차 추가.
   - 보안 정책/운영 지침을 `AGENTS.md` 또는 별도 보안 가이드에 기록.

## 검증 체크리스트
- `make setup_env` 실행 시 bastion을 통한 `ssh-keyscan` 로그가 확인되는지 검증.
- SSH 최초 접속 시 fingerprint 확인 프롬프트가 정상적으로 출력되고, 이후 자동화에서 재사용 가능한지 테스트.
- Docker 컨텍스트(`docker node ls`)가 Host key 검증 활성 상태에서 정상 동작하는지 확인.
- Ansible `ansible -m ping all` 실행이 host key 검증을 통과하는지 확인.

## 참고 문서
- `docs/troubleshooting/ssh_error_known_hosts.md`
- `AGENTS.md`

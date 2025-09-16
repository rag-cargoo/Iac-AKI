# Ansible SSH 연결 문제 및 트러블슈팅 기록

## 1. 문제 상황
Ansible 플레이북 실행 시, 모든 호스트가 `UNREACHABLE` 상태로 실패함:

fatal: [manager]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: Can't open user config file $HOME/.ssh/config: No such file or directory", "unreachable": true}
fatal: [worker1]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: Can't open user config file $HOME/.ssh/config: No such file or directory", "unreachable": true}
fatal: [worker2]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: Can't open user config file $HOME/.ssh/config: No such file or directory", "unreachable": true}

go
코드 복사

- 원인: Ansible `ansible.cfg` 파일 내 `[ssh_connection]` 섹션에서
  ```ini
  ssh_args = -F $HOME/.ssh/config
를 사용했는데, $HOME 변수 치환이 Ansible에서 제대로 적용되지 않아 발생.

하드코딩(/home/aki/.ssh/config) 하면 로컬에서는 동작하지만, 다른 환경에서는 작동하지 않아 이식성이 떨어짐.

2. 시도한 해결책
SSH config 경로 하드코딩

ini
코드 복사
ssh_args = -F /home/aki/.ssh/config
✅ 로컬 환경에서는 성공

❌ 다른 사용자 환경에서는 하드코딩으로 인해 문제가 발생

$HOME 변수 사용

ini
코드 복사
ssh_args = -F $HOME/.ssh/config
❌ Ansible이 $HOME 변수를 치환하지 못해 동일 오류 발생

SSH config 제거

[ssh_connection]에서 ssh_args 옵션 제거

Ansible이 기본 SSH 설정(~/.ssh/config 또는 SSH 에이전트) 사용

✅ 모든 노드에 정상 연결 성공

3. 최종 설정 (권장)
ansible.cfg
ini
코드 복사
[defaults]
inventory = ../../scripts/core_utils/dynamic_inventory.py
host_key_checking = False
remote_user = ubuntu
collections_path = ~/.ansible/collections

[inventory]
enable_plugins = script

[ssh_connection]
# ssh_args 제거, 기본 SSH 에이전트와 config 사용
권장 사항
SSH 키는 SSH 에이전트에 미리 추가 (ssh-add <key.pem>)

Ansible에서 환경 의존적인 경로 사용을 최소화

필요 시 ~/.ssh/config 작성, Ansible ssh_args는 가능하면 제거

4. 추가 팁
SSH 연결 테스트:

bash
코드 복사
ssh swarm-manager
ssh worker1
ssh worker2
워커 노드 조인 실패 시, Swarm 토큰 및 advertise_addr 확인

플레이북에서 환경 변수로 IP/토큰 관리:

yaml
코드 복사
worker_join_token: "{{ hostvars[groups['swarm_manager'][0]]['worker_join_token'] }}"
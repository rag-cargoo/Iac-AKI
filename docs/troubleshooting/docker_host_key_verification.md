# Docker CLI `Host key verification failed` 문제

## 증상
- `make run` 이후 `docker context use swarm-manager` 상태에서 `docker service ls` 등을 실행하면 아래 오류와 함께 종료됨:

```
error during connect: ... ssh ... Host key verification failed.
```
- 때때로 `ssh_askpass: exec(/usr/bin/ssh-askpass): No such file or directory` 로그가 함께 나타남.

## 원인
- Docker CLI가 SSH 터널(`ssh://swarm-manager`)을 열 때 로컬 `~/.ssh/config` 설정을 그대로 사용.
- 새로 프로비저닝된 Bastion/Manager/Worker 인스턴스의 호스트 키가 `known_hosts`에 없거나, `StrictHostKeyChecking` 기본값이 `yes`라서 검증에 실패함.
- 자동화 스크립트가 `StrictHostKeyChecking=no` 등을 지정하지 않으면 Docker CLI가 프롬프트 없이 바로 종료하면서 위 오류가 발생한다.

## 해결
1. `run/common/setup_env.sh`에서 생성하는 SSH 블록에 다음 옵션을 추가한다.
   - `StrictHostKeyChecking no`
   - `UserKnownHostsFile /dev/null`
   - `BatchMode yes`
   - `IdentitiesOnly yes`
2. `make setup_env` 또는 `make run`을 다시 실행해 SSH 설정을 갱신한다.
3. 이후 `docker service ls`, `docker node ls` 등 Docker CLI 명령이 정상 출력되는지 확인한다.

### 2025-09-27 추가 개선
- `run/common/connect_service_tunnel.sh`가 더 이상 베스천에서 직접 포트포워드를 시도하지 않고,
  실제 서비스가 배치된 노드(`swarm-manager`, `worker1` 등)에 SSH 접속한 뒤 `127.0.0.1:<port>`로 터널을 잡도록 변경했다.
- 서비스가 워커 노드에 떠 있어도 자동으로 해당 노드 호스트를 찾아서 터널을 열 수 있으며,
  필요 시 안내에 따라 수동으로 노드 별칭이나 IP를 지정할 수 있다.
- `run/common/setup_env.sh`가 Docker CLI 컨텍스트(`docker context use swarm-manager`)까지 자동으로 맞춰 준다.
- 현재는 `DOCKER_HOST`를 추가로 export하지 않는다. 컨텍스트 기반 CLI만 사용하고, 오래된 스크립트를 위해 필요하면 직접 설정한다.
- 터널이 열렸다면 로컬에서 `curl -I http://localhost:<port>`로 바로 응답을 확인할 수 있다.

> 참고: Ansible 실행 경로에서는 `ansible.cfg`가 이미 `StrictHostKeyChecking=False`와 `ANSIBLE_SSH_ARGS`를 지정하고 있으므로 문제가 없지만, Docker CLI는 SSH 옵션을 별도로 받아오지 않으므로 위 설정이 필요하다.

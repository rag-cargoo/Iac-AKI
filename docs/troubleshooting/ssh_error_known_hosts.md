# SSH 호스트 키 / known_hosts 문제 정리

정기적으로 Terraform으로 인스턴스를 재생성하거나 새 환경을 만들 때 Bastion, Manager, Worker의 SSH 호스트 키가 달라집니다. 이때 로컬 `~/.ssh/known_hosts` 또는 Docker 컨텍스트에서 이전 키를 참고하고 있으면 Ansible과 Docker CLI 모두 연결에 실패할 수 있습니다. 아래 절차를 따라 한 번에 정리하세요.

## 주요 증상
- `make run` 또는 플레이북 실행 시 `Host key verification failed`, `REMOTE HOST IDENTIFICATION HAS CHANGED!` 오류가 발생한다.
- Docker 컨텍스트가 `swarm-manager`로 잡혀 있을 때 `docker node ls` 실행 시 `Host key verification failed.` 메시지와 함께 종료된다.
- 새로 생성된 호스트에 SSH로 접속하려 하면 `'Are you sure you want to continue connecting (yes/no/[fingerprint])?'` 프롬프트가 계속 뜬다.

## 원인 요약
- 인스턴스를 새로 만들면 호스트 키가 바뀌지만, 로컬 `known_hosts`는 이전 fingerprint를 그대로 유지한다.
- Docker CLI는 SSH를 통해 원격 Swarm에 연결할 때 로컬 SSH 설정을 그대로 사용하므로, `StrictHostKeyChecking`이 기본값이면 즉시 연결이 차단된다.
- Ansible은 `host_key_checking` 설정과 SSH 옵션에 따라 동일한 검증 절차를 거친다.

## 해결 절차

### 1. 자동 등록 스크립트 재실행 (권장)
`run/common/setup_env.sh`는 Terraform 출력에 포함된 Bastion/Manager/Worker 주소를 사용해 `ssh-keyscan`으로 최신 호스트 키를 가져옵니다. 다음 명령으로 환경을 새로 준비하면 대부분의 문제가 해결됩니다.

```bash
make setup_env             # 또는 make run, make setup_env_refresh
```

스크립트는 다음 작업을 수행합니다.
- 베스천과 내부 노드의 이전 키를 `ssh-keygen -R`으로 제거
- 최신 fingerprint를 `ssh-keyscan -H`로 받아 `~/.ssh/known_hosts`에 재등록
- SSH config 블록에 `StrictHostKeyChecking no`, `UserKnownHostsFile /dev/null`, `BatchMode yes`, `IdentitiesOnly yes`를 적용해 Docker CLI도 즉시 사용할 수 있도록 맞춤

### 2. 수동으로 known_hosts 정리 (예외 상황)
자동화가 실행되지 않거나 특정 노드만 갱신해야 한다면 `ssh-keygen -R`로 개별 항목을 지웁니다.

```bash
ssh-keygen -f ~/.ssh/known_hosts -R "<기존 IP 또는 호스트명>"
ssh-keyscan -H <새 IP> >> ~/.ssh/known_hosts
```

프롬프트가 떠 있는 SSH 세션은 종료 후 다시 연결해야 새 fingerprint가 저장됩니다.

### 3. Ansible 안전 장치
`ansible.cfg`에는 이미 다음 옵션이 포함돼 있어 초기 실행 시 호스트 키 때문에 중단되지 않습니다.

```ini
[defaults]
host_key_checking = False
```

만약 별도 환경에서 이 설정이 빠졌다면 위 옵션을 다시 활성화하거나, 앞선 자동 등록 스크립트를 사용하세요.

### 4. Docker CLI 전용 체크 포인트
- `run/common/setup_env.sh`가 SSH config에 추가한 옵션 덕분에 Docker CLI는 별도 프롬프트 없이 새 노드에 접속합니다.
- 만약 수동으로 Docker 컨텍스트를 만든 경우 아래 항목이 포함돼 있는지 확인하세요.

```
Host swarm-manager
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    BatchMode yes
    IdentitiesOnly yes
```

## 검증 방법
- `ssh bastion-host`, `ssh swarm-manager`로 프롬프트 없이 접속되는지 확인합니다.
- `docker context use swarm-manager && docker node ls`가 오류 없이 실행되는지 확인합니다.
- `ANSIBLE_CONFIG=ansible.cfg ansible -m ping all` 명령으로 모든 호스트가 `SUCCESS`를 반환하는지 확인합니다.

## 참고
- 인프라를 재프로비저닝할 때마다 `make setup_env` 또는 `make run`을 다시 실행하면 자동으로 최신 상태를 유지할 수 있습니다.
- 관련 자동화 흐름은 `run/common/setup_env.sh`의 Step 1.5(known_hosts 갱신)와 Step 2(SSH config 적용)에서 수행됩니다.

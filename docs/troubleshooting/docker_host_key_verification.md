# Docker CLI `Host key verification failed` 참고

SSH 호스트 키가 바뀐 뒤 Docker 컨텍스트(`ssh://swarm-manager`)에서 `Host key verification failed`가 발생한다면, 일반적인 해결 절차는 `docs/troubleshooting/ssh_error_known_hosts.md`에 정리되어 있습니다. 아래 내용은 Docker CLI에서 추가로 확인할 포인트만 남겨 두었습니다.

## 체크 리스트
- `make setup_env`를 다시 실행해 `run/common/setup_env.sh`가 Docker 전용 SSH 블록을 갱신했는지 확인합니다.
- `~/.ssh/config`의 `Host swarm-manager` 블록에 다음 옵션이 존재해야 합니다.

```
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
BatchMode yes
IdentitiesOnly yes
```

- 수동으로 컨텍스트를 만든 경우 `docker context update --docker "host=ssh://swarm-manager" swarm-manager` 명령으로 다시 적용합니다.
- 위 내용을 적용하고도 실패한다면, 메인 문서의 “수동으로 known_hosts 정리” 절차를 따라 Bastion/Manager/Worker의 fingerprint를 직접 갱신하세요.

## 서비스 터널 메모 (2025-09-27)
`run/common/connect_service_tunnel.sh`는 서비스가 위치한 노드를 자동으로 찾아 SSH 터널을 엽니다. fingerprint를 갱신한 뒤에는 `make tunnel`이나 관련 스크립트를 다시 실행해 새 호스트 키를 반영해야 합니다.

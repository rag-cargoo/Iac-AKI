# Ansible SSH Known Hosts 문제 트러블슈팅

## 문제 현상
- `make run` 실행 시 Ansible이 `Host key verification failed` 또는 `REMOTE HOST IDENTIFICATION HAS CHANGED!` 오류 발생.
- 원인: Terraform `destroy` → `apply` 과정에서 인스턴스 재생성으로 **호스트 키(fingerprint)가 변경**됨.
- 로컬 `~/.ssh/known_hosts` 파일과 충돌 발생.

## 해결 방법

### 1. Ansible에서 호스트 키 검증 비활성화
`ansible.cfg` 수정:

```ini
[defaults]
inventory = inventory/production/swarm.yml
host_key_checking = False
remote_user = ubuntu

[inventory]
enable_plugins = script
```

- host_key_checking = False → Ansible 실행 시 yes/no 질문 방지

- ssh_args → known_hosts 파일 자체를 사용하지 않음

    👉 Ansible 실행에서 호스트 키 문제 발생하지 않음.



### 2. 로컬 SSH에서 경고 해결 (선택사항)

로컬에서 직접 접속(ssh worker1 등) 시는 여전히 known_hosts 충돌이 발생할 수 있음.
이 경우 기존 키 삭제 후 재접속:
``` bash
ssh-keygen -f ~/.ssh/known_hosts -R "10.0.101.10"
ssh-keygen -f ~/.ssh/known_hosts -R "10.0.102.10"
ssh-keygen -f ~/.ssh/known_hosts -R "10.0.101.11"
```

# 결론

- Ansible 실행만 중요하다면 ansible.cfg 수정으로 문제 해결.

- 로컬 ssh도 깔끔하게 쓰고 싶다면 ssh-keygen -R 명령으로 오래된 키를 삭제.


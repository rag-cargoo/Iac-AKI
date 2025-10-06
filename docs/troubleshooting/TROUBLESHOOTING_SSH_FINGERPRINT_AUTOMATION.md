# SSH Fingerprint 자동 등록 문제

이전 버전의 문서에 있던 자세한 해결 절차는 이제 `docs/troubleshooting/ssh_error_known_hosts.md`에서 통합 관리합니다. 인프라 재프로비저닝 후 호스트 키 프롬프트가 발생할 때는 해당 문서를 확인하세요.

요약만 필요하다면 아래 두 가지만 기억하면 됩니다.
- `make setup_env` 또는 `make run`을 실행하면 `run/common/setup_env.sh`가 bastion/manager/worker의 fingerprint를 자동으로 재등록해 줍니다.
- 예외적으로 자동화가 실패하면 `ssh-keygen -R <IP>`로 기존 키를 지우고 `ssh-keyscan -H <IP>`로 다시 추가하세요.

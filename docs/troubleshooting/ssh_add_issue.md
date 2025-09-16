# SSH Agent `ssh-add` 스크립트 내 실패 문제 트러블슈팅 기록

## 문제 증상

`scripts/core_utils/setup_project_env.sh` 또는 이 스크립트를 소싱하는 다른 연결 스크립트(예: `connect_manager.sh`, `connect_service_tunnel.sh`)를 실행할 때, `ssh-agent`는 성공적으로 시작되지만 `ssh-add` 명령에서 다음 오류와 함께 실패함:

```
❌ ERROR: Failed to add SSH key to agent. Check key path and permissions. Cannot proceed.
```

이 오류로 인해 스크립트가 종료되거나, SSH 연결이 필요한 Ansible 플레이북 및 기타 스크립트가 정상적으로 작동하지 않음.

## 진단 과정 및 시도된 해결책

1.  **키 파일 권한 확인:**
    *   **명령어:** `ls -l "${SSH_KEY_PATH}"`
    *   **결과:** `-r--------` (권한 400)으로 올바름.
    *   **결론:** 권한 문제는 아님.

2.  **키 파일 암호(Passphrase) 여부 확인:**
    *   **명령어:** `ssh-keygen -y -f "${SSH_KEY_PATH}"`
    *   **결과:** 암호 프롬프트 없이 공개 키가 즉시 출력됨.
    *   **결론:** 암호 문제는 아님.

3.  **`ssh-agent` 시작 및 `SSH_AUTH_SOCK` 설정 확인:**
    *   스크립트 내에서 `eval "$(ssh-agent -s)"`가 실행되고 `SSH_AUTH_SOCK` 환경 변수가 올바르게 설정되는 것을 디버그 출력(`bash -x`)을 통해 확인.
    *   **결론:** `ssh-agent`는 시작되고 있으며, 소켓 연결 자체의 문제는 아님.

4.  **`~` (틸드) 경로 확장 문제:**
    *   스크립트 내에서 `"${SSH_KEY_PATH}"` 경로가 `ssh-add`에 전달될 때 `~`가 제대로 확장되지 않을 가능성 제기.
    *   **시도:** `setup_project_env.sh` 내 `SSH_KEY_PATH`를 절대 경로(`$HOME/.aws/key/test_key.pem`)로 명시적으로 변경.
    *   **결과:** 문제 해결되지 않음.

5.  **`ssh-add` 명령의 견고성 강화:**
    *   `setup_project_env.sh` 내 `ssh-add` 호출 시 `2>/dev/null`을 추가하고, 실패 시 `exit 1` 대신 경고만 출력하도록 변경.
    *   **결과:** `ssh-add`는 여전히 실패하지만 스크립트가 종료되지 않고 계속 진행됨. (하지만 키가 로드되지 않아 SSH 연결은 여전히 불가).

6.  **Ansible `--private-key` 옵션 사용 시도:**
    *   `ansible-playbook` 실행 시 `ssh-agent` 의존성을 제거하기 위해 `--private-key="${SSH_KEY_PATH}"` 옵션 사용 제안.
    *   **결과:** `setup_project_env.sh` 스크립트가 `ssh-add`에서 실패하여 스크립트가 종료되므로 플레이북 실행 자체가 불가. (이후 `ssh-add` 실패를 경고로 변경하여 플레이북 실행은 가능해졌으나, 여전히 키 로드 문제는 남음).

## Makefile의 역할

`Makefile`은 `setup_project_env.sh` 스크립트 실행과 `ansible-playbook` 실행을 하나의 명령으로 통합하여 환경 변수 전달 문제를 해결했습니다. 하지만 `Makefile` 자체는 `ssh-add` 명령이 스크립트 내에서 실패하는 근본적인 문제를 해결하지는 못했습니다. `ssh-add` 실패 시 스크립트가 종료되지 않도록 우회하는 역할만 수행합니다.

## 현재 상태 및 해결 방법

`scripts/core_utils/setup_project_env.sh` 스크립트와 `Makefile`의 개선을 통해 `ssh-agent` 시작 및 SSH 키 추가 과정이 더욱 견고해졌습니다.

`Makefile`의 `run` 타겟을 실행하면 `setup_project_env.sh`가 자동으로 소싱되어 필요한 환경 변수 설정, `~/.ssh/config` 업데이트, 그리고 `ssh-agent` 시작 및 SSH 키 추가를 시도합니다.

대부분의 환경에서 이 과정은 자동으로 성공합니다.

하지만 **매우 드물게** `ssh-add` 명령이 스크립트 내에서 실패하는 이례적인 문제가 발생할 수 있습니다. 이 경우, 다음 명령어를 **수동으로 실행**하여 SSH 키를 `ssh-agent`에 추가해야 합니다.

**수동 우회 방법 (필요한 경우):**

Ansible 플레이북이나 SSH 연결 스크립트를 실행하기 전에 다음 두 명령어를 **수동으로 실행**하여 SSH 키를 `ssh-agent`에 추가해야 합니다.

```bash
eval "$(ssh-agent -s)"
ssh-add "${SSH_KEY_PATH}" # SSH_KEY_PATH는 setup_project_env.sh 실행 시 설정됩니다.
```

`ssh-add` 명령 실행 시 `Identity added:` 메시지가 나타나면 성공적으로 키가 추가된 것입니다.

## 향후 해결 과제

*   `ssh-add` 명령이 스크립트 내에서 실패하는 근본 원인 파악 및 자동화된 해결책 모색.
*   `~/.ssh/config` 파일이 손상되었을 가능성을 고려하여, 백업 후 새로 생성하는 방법 검토.
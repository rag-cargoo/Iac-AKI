
# AWS + Ansible + Docker Swarm 구축 트러블슈팅 기록

> 프로젝트 진행 중 발생한 문제와 해결 과정을 기록한 문서입니다.  
> Terraform, Ansible, Docker Swarm, Linux 환경 관련 문제와 해결법을 포함합니다.

---

## 1. 동적 인벤토리 실행 실패

**문제:**  
Ansible 실행 시 dynamic_inventory.py가 작동하지 않고 환경 변수 미설정 에러 발생.

```text
Error: Missing required environment variables: BASTION_PUBLIC_IP, MANAGER_PRIVATE_IP, SSH_KEY_PATH
Please source run/common/setup_env.sh first.
```

**원인:**
*   동일 세션에서 환경 변수가 로드되지 않았음.
*   Ansible이 dynamic_inventory.py를 호출할 때 환경 변수를 찾지 못함.

**해결 방법:**
*   반드시 프로젝트 환경 설정 스크립트를 먼저 실행:
    ```bash
    source run/common/setup_env.sh
    ```
*   Makefile을 만들어 환경 설정 + Ansible 플레이북 실행을 한 번에 수행:
    ```makefile
    run:
      @ANSIBLE_CONFIG=$(ANSIBLE_CFG) bash -c "source $(SETUP_SCRIPT) && ansible-playbook $(ANSIBLE_PLAYBOOK) -i $(INVENTORY_FILE)"
    ```

**결과:**
동적 인벤토리 정상 작동, Ansible 호스트 인식 완료.

## 2. 워커 노드 Swarm 조인 실패

**문제:**
플레이북에서 워커 노드 조인이 안 됨. `host pattern not found` 경고 발생.

**원인:**
*   이전 dynamic inventory 문제로 그룹 및 호스트 변수가 정상 전달되지 않았음.
*   `hostvars` 참조가 올바르지 않거나 매니저 토큰을 가져오지 못함.

**해결 방법:**
*   Makefile과 환경 변수 로드를 정상화
*   플레이북에서 manager `hostvars`를 올바르게 참조:
    ```yaml
    join_token: "{{ hostvars[groups['manager'][0]]['worker_join_token'] }}"
    remote_addrs: ["{{ hostvars[groups['manager'][0]]['ansible_host'] }}:2377"]
    ```

**결과:**
워커 노드 정상 조인 확인, `docker node ls` 출력 정상.

## 3. Python 인터프리터 경고

**문제:**
Ansible 플레이북 실행 시 다음 경고 발생:

```text
[WARNING]: Platform linux on host manager is using the discovered Python interpreter at /usr/bin/python3.10
```

**원인:**
*   Ansible이 각 호스트에서 Python 경로를 자동으로 탐지할 때, 향후 다른 Python 설치 시 경로가 달라질 수 있음.

**해결 방법:**
*   현재 환경에서는 무시 가능.
*   필요 시 `ansible_python_interpreter`를 호스트별로 지정 가능.
    ```ini
    [all:vars]
    ansible_python_interpreter=/usr/bin/python3
    ```

**결과:**
경고만 발생, 플레이북 실행에는 영향 없음.

## 4. SSH 연결 및 bastion 문제

**문제:**
*   호스트가 private subnet에 있어 직접 접근 불가
*   Ansible 실행 시 SSH 연결 실패

**원인:**
*   Bastion을 통한 SSH 터널링 설정 누락
*   `ssh-agent`에 키 미등록

**해결 방법:**
*   SSH common args는 `inventory_plugins/swarm.py`에서 자동으로 주입되도록 관리합니다.
*   `ssh-agent` 실행 및 키 추가:
    ```bash
    eval "$(ssh-agent -s)"
    ssh-add "${SSH_KEY_PATH}"
    ```

**결과:**
Ansible 및 Docker CLI 정상 연결.

## 5. Makefile을 통한 실행 통합

**목적:**
*   환경 변수 로드 + Ansible 플레이북 실행을 한 번에 수행
*   반복되는 환경 문제 최소화

**내용:**
```makefile
run:
  @ANSIBLE_CONFIG=$(ANSIBLE_CFG) bash -c "source $(SETUP_SCRIPT) && ansible-playbook $(ANSIBLE_PLAYBOOK) -i $(INVENTORY_FILE)"

setup_env:
  @bash -c "source $(SETUP_SCRIPT)"

ansible:
  @ANSIBLE_CONFIG=$(ANSIBLE_CFG) bash -c "source $(SETUP_SCRIPT) && ansible-playbook $(ANSIBLE_PLAYBOOK) -i $(INVENTORY_FILE)"
```

**결과:**
*   환경 변수 관련 오류 최소화
*   플레이북 실행 단순화
*   재사용성 확보

## 6. 요약

| 문제 원인             | 해결 방법                                    | 상태 |
| :-------------------- | :------------------------------------------- | :--- |
| Dynamic Inventory 실행 실패 | `run/common/setup_env.sh` 먼저 실행, Makefile 사용 | 해결 |
| 워커 노드 Swarm 조인 실패 | 플레이북 수정 및 환경 변수 정상화            | 해결 |
| Python 인터프리터 경고    | 무시 가능, 필요 시 `ansible_python_interpreter` 지정 | 경고만 |
| SSH 연결 실패           | Bastion 설정, `ssh-agent` 키 추가            | 해결 |
| 반복 실행 번거로움      | Makefile 통합 실행                           | 해결 |
| Docker CLI 호스트 키 검증 실패 | `setup_env.sh`에서 SSH 옵션 강화, `StrictHostKeyChecking no` 설정 | 해결 |

> Docker CLI 관련 상세 원인은 `docs/troubleshooting/docker_host_key_verification.md` 참고.

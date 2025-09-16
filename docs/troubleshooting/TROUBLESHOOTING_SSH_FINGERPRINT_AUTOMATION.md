문서 내용
# SSH Fingerprint 자동 등록 문제 (Terraform + Ansible + Bastion)

## 문제 상황
Terraform으로 Bastion/Manager/Worker 인스턴스를 생성 후,  
`make run` 으로 Ansible을 실행하면 다음 메시지가 발생하여 진행이 멈춤:



The authenticity of host '13.209.229.72 (13.209.229.72)' can't be established.
ED25519 key fingerprint is SHA256:xxxxxxxxxxxxxxxxxxxx.
Are you sure you want to continue connecting (yes/no/[fingerprint])?


이는 **새로 생성된 EC2 인스턴스의 SSH 호스트 키가 아직 `~/.ssh/known_hosts`에 등록되지 않았기 때문**에 발생.

---

## 원인
- SSH는 최초 접속 시 호스트 키(Fingerprint)를 확인 후 `known_hosts` 파일에 저장함.
- Bastion 및 내부 Manager/Worker는 매번 새로 생성되므로 fingerprint가 달라질 수 있음.
- 따라서 Ansible Playbook 실행 시, **yes 입력 대기 상태**가 되어 자동화가 멈추는 문제가 발생.

---

## 해결 방법

### ✅ 적용한 방법 (자동화)
`Makefile` 실행 흐름에서 **Step 2.5**를 추가해,  
Terraform output으로 얻은 Bastion/Manager/Worker IP를 기반으로 `ssh-keyscan`을 자동 실행하여 `~/.ssh/known_hosts`에 등록하도록 구현.

```bash
# Step 2.5: Register SSH known_hosts
@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
@echo "🔹 Step 2.5: Register SSH known_hosts"
@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ssh-keyscan -H $(BASTION_PUBLIC_IP) >> ~/.ssh/known_hosts 2>/dev/null
ssh-keyscan -H $(MANAGER_PRIVATE_IP) >> ~/.ssh/known_hosts 2>/dev/null
for ip in $(WORKER_PRIVATE_IPS); do \
    ssh-keyscan -H $$ip >> ~/.ssh/known_hosts 2>/dev/null; \
done
@echo "✅ Hosts added to known_hosts to avoid authenticity prompt"


Bastion/Manager/Worker IP는 모두 terraform output 으로 동적으로 가져옴.

별도의 하드코딩 없이 새로 생성된 인프라 환경에서도 항상 자동 적용됨.

이후 make run 실행 시 fingerprint 확인 프롬프트가 발생하지 않고, 바로 Ansible Playbook이 진행됨.

결과

make run 실행 시:

Terraform outputs → SSH config → known_hosts 자동 등록 → SSH Key 로딩 → Ansible 실행 순으로 원활히 진행.

Ansible Playbook 정상 완료:

Docker 설치 및 환경 구성

Swarm Manager 초기화

Worker 노드 Swarm 조인

결과적으로 완전 자동화된 Docker Swarm 클러스터 구축이 가능해짐 🎉

참고

Bastion/Manager/Worker 인스턴스가 새로 생성될 때마다 fingerprint가 바뀔 수 있음.
make run이 실행될 때 매번 최신 IP로 ssh-keyscan을 수행하므로 별도의 수동 조치가 필요 없음.
# AWS, Ansible, Docker Swarm을 이용한 클러스터 구축 프로젝트

## 1. 프로젝트 개요

이 프로젝트는 Terraform을 사용하여 AWS에 인프라를 구축하고, Ansible을 사용하여 Docker Swarm 클러스터를 자동으로 구성 및 배포하는 것을 목표로 합니다.

**주요 기술 스택:**
*   **Infrastructure as Code:** Terraform
*   **Configuration Management:** Ansible
*   **Container Orchestration:** Docker Swarm
*   **Cloud Provider:** AWS

## 2. 사전 준비 사항

프로젝트를 실행하기 위해 다음 도구들이 필요합니다.

*   [Terraform](https://www.terraform.io/downloads.html)
*   [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
*   [AWS CLI](https://aws.amazon.com/cli/)
*   AWS 계정 및 IAM User Access Key/Secret Key

## 3. 사용 방법

### 3.1. 인프라 구축 (Terraform)

`Iac/TERRAFORM` 디렉토리에서 Terraform을 실행하여 AWS 인프라를 생성합니다. **변수 정의를 위해 `terraform.tfvars` 파일을 사용해야 합니다.** 자세한 내용은 `Iac/TERRAFORM/TFVARS_GUIDE.md`를 참조하십시오.

1.  Terraform 초기화 및 프로바이더 다운로드:
    ```bash
    cd Iac/TERRAFORM
    terraform init -reconfigure
    ```
2.  인프라 프로비저닝:
    ```bash
    terraform apply -auto-approve
    ```

### 3.2. 서버 구성 및 배포 (Ansible)

Ansible은 Terraform output을 기반으로 동적 인벤토리(`scripts/core_utils/dynamic_inventory.py`)를 사용합니다. `ansible.cfg` 파일은 이 동적 인벤토리를 가리키도록 설정되어 있습니다.

1.  Docker 설치 및 Swarm 클러스터 구성:
    ```bash
    cd Iac/ANSIBLE
    ansible-playbook \
        -i ../../scripts/core_utils/dynamic_inventory.py \
        join_workers_direct.yml \
        --private-key="${SSH_KEY_PATH}"
    ```
2.  Nginx 테스트 서비스 배포 (선택 사항):
    ```bash
    cd Iac/ANSIBLE
    ansible-playbook test_playbooks/deploy_nginx.yml
    ```

### 3.3. 서비스 확인

Swarm 매니저 노드에 접속하여 아래 명령어로 서비스 상태를 확인할 수 있습니다.

```bash
# 서비스 목록 확인
docker service ls

# nginx_web 서비스의 상세 상태 확인
docker service ps nginx_web
```

## 4. EC2 인스턴스 접속 방법

접속 스크립트들은 `scripts/core_utils/setup_project_env.sh` 스크립트를 통해 필요한 환경 변수(IP 주소, SSH 키 경로 등)를 로드합니다.

1.  환경 변수 로드:
    ```bash
    source scripts/core_utils/setup_project_env.sh
    ```
    **참고:** 이 스크립트를 실행하면 로컬에서 Docker Swarm 명령어를 직접 사용할 수 있도록 `export DOCKER_HOST="ssh://swarm-manager"` 명령어가 출력됩니다. 이 명령어는 현재 터미널 세션에서 Docker CLI가 원격 Swarm 클러스터와 통신하도록 설정하는 역할을 합니다. 전체 프로젝트 진행에 필수는 아니지만, 로컬에서 `docker node ls`와 같은 명령어를 사용하려면 이 명령어를 직접 실행해야 합니다.

### 4.3. SSH Agent 문제 해결 (필수)

일부 환경에서 `ssh-agent`에 SSH 키를 자동으로 추가하는 데 문제가 발생할 수 있습니다. 이 경우, Ansible 플레이북이나 SSH 연결 스크립트를 실행하기 전에 다음 명령어를 **수동으로 실행**하여 SSH 키를 `ssh-agent`에 추가해야 합니다.

```bash
eval "$(ssh-agent -s)"
ssh-add "${SSH_KEY_PATH}" # SSH_KEY_PATH는 환경 변수로 설정된 SSH 키 파일 경로입니다.
```

`ssh-add` 명령 실행 시 `Identity added:` 메시지가 나타나면 성공적으로 키가 추가된 것입니다.

2.  Bastion Host 접속:
    ```bash
    ./scripts/connect_bastion.sh
    ```
3.  Swarm Manager 노드 직접 접속 (추천):
    ```bash
    ./scripts/connect_manager.sh
    ```
4.  범용 SSH 터널링 스크립트 사용:
    ```bash
    ./scripts/connect_service_tunnel.sh
    ```
    (실행 후 프롬프트에 따라 IP 및 포트 입력)

---

***Note:*** *이 문서는 프로젝트의 현재 상태를 반영합니다. 프로젝트에 변경사항이 발생할 경우, 이 `README.md` 파일과 `PROJECT_PLAN.md` 파일을 반드시 업데이트하여 최신 상태를 유지해야 합니다.*

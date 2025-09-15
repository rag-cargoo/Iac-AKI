# 프로젝트: AWS Ansible Docker Swarm

## 1. 프로젝트 목표

이 프로젝트는 Terraform을 사용하여 AWS에 인프라를 구축하고, Ansible을 사용하여 Docker Swarm 클러스터를 자동으로 구성 및 배포하는 것을 목표로 합니다. 최종적으로는 컨테이너화된 애플리케이션을 배포할 수 있는 Docker Swarm 환경을 구축합니다.

## 2. 인프라 구성 (Terraform) - 완료

Terraform을 통해 다음과 같은 AWS 리소스 생성을 완료했습니다.

*   **VPC, Subnet, Gateway 등 네트워크 환경**
*   **EC2 인스턴스:** Bastion, Manager, Worker (동적 확장 가능)
*   **보안 그룹**

## 3. 서버 구성 및 클러스터 구축 (Ansible) - 완료

Ansible을 사용하여 프로비저닝된 EC2 인스턴스의 초기 설정 및 Docker Swarm 클러스터 구성을 완료했습니다.

*   **Ansible 설정:** 동적 인벤토리(`scripts/core_utils/dynamic_inventory.py`)를 사용하여 Terraform output에서 호스트 정보를 자동으로 가져오도록 설정.
*   **Docker 설치:** 모든 노드에 Docker Engine 및 필요 패키지 설치 완료.
*   **Docker Swarm 클러스터 구성:**
    *   `manager` 노드를 Swarm 매니저로 초기화 완료.
    *   `worker` 노드들을 클러스터에 조인 완료.

## 4. 클러스터 기능 테스트 (Nginx 배포) - 완료

클러스터가 정상적으로 동작하는지 확인하기 위해 Nginx 서비스를 배포하여 기능 테스트를 완료했습니다. 테스트용 `deploy_nginx.yml` 플레이북은 현재 `Iac/ANSIBLE/test_playbooks` 디렉토리에 있습니다.

*   **Playbook:** `deploy_nginx.yml` (테스트용, `Iac/ANSIBLE/test_playbooks`에 위치)
*   **배포:** `nginx_web` 서비스를 3개의 복제본으로 배포하여 클러스터 기능 확인 완료.
*   **결과:** 매니저 노드와 워커 노드에 Nginx 컨테이너가 분산 배포되어 실행되는 것을 `docker service ps` 명령으로 확인 완료.

## 5. 다음 단계 (제안)

*   **모니터링 스택 구축:** `worker2` (이전 `private_monitoring`) 인스턴스에 Prometheus, Grafana 등을 설치하여 클러스터 및 컨테이너 모니터링 환경 구축.
*   **고가용성(HA) 구성:** Swarm 매니저 노드를 추가하여 매니저 이중화 구성.
*   **CI/CD 연동:** GitHub Actions 등과 연동하여 애플리케이션 자동 배포 파이프라인 구축.

## 6. 트러블슈팅 및 해결 과정 기록

*   **환경 설정 자동화:** `scripts/core_utils/setup_project_env.sh` 스크립트를 통해 Terraform output 환경 변수 내보내기를 자동화.
*   **SSH 접속 문제:** `ssh-agent` 설정 및 `~/.ssh/config` 파일, 키 권한 문제 등을 통해 해결. `scripts/connect_manager.sh` 스크립트를 통해 접속 자동화. (환경 변수는 `scripts/core_utils/setup_project_env.sh`에서 로드)
*   **Ansible 모듈 인식 문제:** `community.docker` 컬렉션 경로를 Ansible이 인식하지 못하는 문제가 발생. `ansible.cfg`에 `collections_paths`를 명시적으로 지정했으나 해결되지 않아, `shell` 모듈로 `docker service create` 명령어를 직접 실행하는 방식으로 우회하여 해결.
*   **Terraform "undeclared resource" 오류:** `ec2.tf` 파일의 내용 불일치로 인해 발생. `ec2_verified.tf` 파일을 통해 `ec2.tf`를 최신화하여 해결.
*   **Terraform `cidrcontains` / `cidrnetmask` 함수 오류:** `ec2.tf`에서 워커 인스턴스의 서브넷 할당 로직 문제. `startswith` 함수를 사용하여 IP 주소 기반으로 서브넷을 동적으로 할당하도록 수정하여 해결.
*   **Terraform 변수 관리 개선:** `variables.tf`에서 `default` 값 제거 및 `terraform.tfvars`를 통한 변수 관리 도입. `Iac/TERRAFORM/TFVARS_GUIDE.md` 문서 추가.
*   **Terraform 리소스 명칭 통일:** `private_app_a` -> `manager`, `private_app_b` -> `worker1`, `private_monitoring` -> `worker2`로 리소스 이름 및 관련 태그, output 이름 통일.
*   **Ansible SSH 키 경로 관리:** 스크립트에서 SSH 키 경로를 하드코딩하는 대신 Terraform output에서 가져오도록 변경.
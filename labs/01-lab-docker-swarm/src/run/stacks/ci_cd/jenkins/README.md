# Jenkins Stack (CI/CD)

이 디렉터리는 Swarm 매니저 노드에 Jenkins LTS를 배포하기 위한 Docker stack 정의를 담고 있습니다. Jenkins는 `/var/jenkins_home` 볼륨에 상태를 저장하며, Docker socket을 마운트해 컨테이너 빌드/배포 파이프라인을 실행할 수 있습니다.

## 사전 준비
1. `make tf-apply`로 ALB + Route 53 구성을 마친 뒤 `https://*.goopang.me` DNS가 Swarm 매니저(8080)로 연결되는지 확인합니다.
2. `make setup_env`로 SSH/Docker 컨텍스트를 전환합니다.(`docker context use swarm-manager`)
3. 필요하면 `docker volume inspect jenkins-data`로 기존 데이터 볼륨을 확인하거나 백업합니다.

## 배포 절차
```bash
# labs/01-lab-docker-swarm 디렉터리에서 실행
make jenkins_deploy
```
이 명령은 `docker stack deploy -c src/run/stacks/ci_cd/jenkins/stack.yml jenkins`를 호출합니다. Jenkins UI는 ALB → Swarm 매니저 8080 포트로 노출되며, 내부적으로는 `jenkins` 네임의 overlay 네트워크가 생성됩니다.

### 상태 확인
```bash
docker stack services jenkins
docker stack ps jenkins
```
헬스 체크가 통과하면 ALB Target Group에서도 `healthy`로 표시됩니다. 초기 관리자 비밀번호는 `/var/jenkins_home/secrets/initialAdminPassword`에 있습니다.

## 스택 제거
```bash
make jenkins_remove
```
볼륨(`jenkins-data`)은 삭제되지 않으므로 재배포 시 기존 설정을 재사용할 수 있습니다. 완전히 초기화하려면 `docker volume rm jenkins-data`를 수동으로 삭제하세요.

## 참고
- Jenkins에서 Docker 빌드를 수행하려면 컨테이너 안에서 `/var/run/docker.sock`을 사용합니다. 필요 시 Role/권한을 적절히 관리하거나 에이전트 노드를 별도로 구성하세요.
- Jenkins 파이프라인 대상 코드/스크립트는 `src/run/apps/<service>` 등 별도 디렉터리에서 관리하고, Jenkins Job에서 해당 경로를 Workspace로 사용하면 됩니다.

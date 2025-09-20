# Docker Swarm 주요 명령어 가이드

Docker Swarm 클러스터를 관리하고 운영할 때 자주 사용하는 명령어들을 정리한 문서입니다.

**참고:** 모든 관리 명령어는 **Swarm 매니저 노드**에서 실행해야 합니다.

---

## 1. 클러스터 관리 (Cluster Management)

| 명령어 | 설명 |
| --- | --- |
| `docker swarm init` | 현재 노드를 Swarm 매니저로 초기화하여 새로운 클러스터를 생성합니다. |
| `docker swarm join-token worker` | 워커 노드가 클러스터에 참여할 때 필요한 조인 토큰을 보여줍니다. |
| `docker swarm join-token manager` | 매니저 노드가 클러스터에 참여할 때 필요한 조인 토큰을 보여줍니다. |
| `docker swarm join --token <TOKEN> <MANAGER_IP:PORT>` | 새로운 노드를 기존 클러스터에 참여시킵니다. |
| `docker swarm leave` | 현재 노드를 클러스터에서 탈퇴시킵니다. (매니저에서 실행 시 `--force` 옵션 필요) |

---

## 2. 노드 관리 (Node Management)

| 명령어 | 설명 |
| --- | --- |
| `docker node ls` | 클러스터에 포함된 모든 노드의 목록과 상태를 보여줍니다. (가장 많이 사용) |
| `docker node inspect <NODE_ID>` | 특정 노드의 상세 정보를 JSON 형식으로 보여줍니다. |
| `docker node update --availability drain <NODE_ID>` | 특정 노드의 상태를 `drain`으로 변경하여 더 이상 새로운 작업을 할당받지 않도록 합니다. (점검/업데이트 시 유용) |
| `docker node update --availability active <NODE_ID>` | `drain` 상태의 노드를 다시 `active` 상태로 변경합니다. |
| `docker node promote <NODE_ID>` | 특정 워커 노드를 매니저로 승격시킵니다. |
| `docker node demote <NODE_ID>` | 특정 매니저 노드를 워커로 강등시킵니다. |
| `docker node rm <NODE_ID>` | 클러스터에서 특정 노드를 제거합니다. (해당 노드가 `down` 상태이거나 `docker swarm leave`로 탈퇴한 후에만 가능) |

---
l
## 3. 서비스 관리 (Service Management)

서비스는 Swarm 클러스터에서 실행되는 컨테이너의 정의입니다.

| 명령어 | 설명 |
| --- | --- |
| `docker service create --name <SERVICE_NAME> --replicas <NUM> -p <HOST_PORT>:<CONTAINER_PORT> <IMAGE>` | 새로운 서비스를 생성하고 배포합니다. (예: `docker service create --name nginx --replicas 3 -p 80:80 nginx:latest`) |
| `docker service ls` | 현재 클러스터에서 실행 중인 모든 서비스의 목록을 보여줍니다. |
| `docker service ps <SERVICE_NAME>` | 특정 서비스에 속한 모든 작업(컨테이너)의 목록과 어느 노드에서 실행 중인지 보여줍니다. (배포 상태 확인 시 필수) |
| `docker service inspect <SERVICE_NAME>` | 특정 서비스의 상세 설정 정보를 보여줍니다. |
| `docker service scale <SERVICE_NAME>=<NUM>` | 실행 중인 서비스의 복제본(replica) 수를 동적으로 조절합니다. (예: `docker service scale nginx=5`) |
| `docker service update --image <NEW_IMAGE> <SERVICE_NAME>` | 실행 중인 서비스의 이미지를 새로운 버전으로 업데이트(롤링 업데이트)합니다. |
| `docker service logs <SERVICE_NAME>` | 특정 서비스의 모든 컨테이너 로그를 취합하여 보여줍니다. |
| `docker service rm <SERVICE_NAME>` | 특정 서비스를 제거합니다. |

---

## 4. 스택 관리 (Stack Management)

스택은 `docker-compose.yml` 파일과 유사한 형식으로 여러 서비스를 한 번에 관리하는 단위입니다.

| 명령어 | 설명 |
| --- | --- |
| `docker stack deploy -c <COMPOSE_FILE.yml> <STACK_NAME>` | YAML 파일을 기반으로 여러 서비스를 한 번에 배포(생성 또는 업데이트)합니다. |
| `docker stack ls` | 현재 클러스터에 배포된 모든 스택의 목록을 보여줍니다. |
| `docker stack services <STACK_NAME>` | 특정 스택에 포함된 모든 서비스의 목록을 보여줍니다. |
| `docker stack ps <STACK_NAME>` | 특정 스택에 포함된 모든 작업(컨테이너)의 상태를 보여줍니다. |
| `docker stack rm <STACK_NAME>` | 특정 스택과 그에 속한 모든 서비스를 한 번에 제거합니다. |

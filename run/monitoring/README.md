# Monitoring Runbook (Prometheus + Grafana)

이 문서는 Docker Swarm 클러스터 위에 모니터링 스택을 올릴 때 필요한 **실행 단계만** 정리합니다. 모든 명령은 저장소 루트( `~/STUDY/ANSIBLE/AWS-ANSIBLE-DockerSwarm` )에서 실행한다고 가정합니다.

---

## 0. 준비: Swarm 환경 변수 로드
```bash
source run/common/setup_env.sh
```
> SSH config, known_hosts, Docker 컨텍스트(`swarm-manager`)가 자동 구성됩니다. 기존에 열려 있던 동일 포트 SSH 터널이 있으면 자동으로 정리한 뒤 새로 연결합니다.

---

## 1. 오버레이 네트워크 생성
```bash
docker network create --driver overlay monitoring_net || true
docker network create --driver overlay logging_net || true
```
> 이미 존재하면 무시됩니다.

---

## 2. 모니터링 스택 배포 (Prometheus + Grafana)
```bash
docker stack deploy -c src/stacks/monitoring/stack.yml monitoring
```

---

## 3. 상태 확인
```bash
docker stack services monitoring
docker stack ps monitoring
```
필요하면 노드 상태도 확인합니다.
```bash
docker node ls
```

---

## 4. 제거
```bash
docker stack rm monitoring
# 스택 정리 후 네트워크 제거 (옵션)
sleep 5
docker network rm monitoring_net logging_net 2>/dev/null || true
```

---
## 5. (옵션) 포트 포워딩
Prometheus(9090), Grafana(3000)에 로컬 브라우저로 접속하려면:
```bash
ssh -N -L 9090:localhost:9090 -L 3000:localhost:3000 swarm-manager
```

---

### 참고
- `src/stacks/monitoring/stack.yml`이 서비스 정의를, `run/monitoring/README.md`가 실행 단계를 담당합니다.
- 동일한 패턴으로 다른 서비스도 `run/<service>/` 아래에 정리할 수 있습니다.
- Grafana 대시보드 JSON은 `run/monitoring/dashboards/` 디렉터리에 보관해 두면 Terraform을 내려도 손쉽게 재사용할 수 있습니다.

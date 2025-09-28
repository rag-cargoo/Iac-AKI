# Monitoring Stack (Prometheus + Grafana)

이 디렉터리는 모니터링 스택 정의 파일을 담고 있습니다.

- `stack.yml` – Swarm 배포 정의 (Prometheus + Grafana)
- `prometheus/prometheus.yml` – Prometheus 스크래이프 설정

실행·배포 절차는 `05-run/monitoring/README.md`를 참고하세요. 거기에서 네트워크 생성 → 스택 배포 → 상태 확인 → 제거 순으로 명령이 정리되어 있습니다.

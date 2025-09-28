# 인프라 모니터링 학습 리소스

## 공식 자료
- [CNCF Observability Landscape](https://landscape.cncf.io/category=observability-and-analysis&format=card-mode)
- [Prometheus + Grafana 통합 가이드](https://prometheus.io/docs/visualization/grafana/)

## 모니터링 구성 요소
1. Metric 수집 (Prometheus, Node Exporter, 서비스별 exporter)
2. 시각화/Alerting (Grafana)
3. 로깅/트레이싱 (Loki, Tempo 등 – 필요 시 확장)

## 실습 로드맵
1. Node Exporter & Prometheus 연동
2. Grafana 대시보드 구축 및 템플릿 변수 활용
3. Alertmanager와 연계한 경보 설정
4. Grafana 대시보드 백업/복원

### Grafana 대시보드 백업/복원 참고
- UI에서 `Share → Export → Save to file`로 JSON을 내려 받아 `run/monitoring/dashboards/` 등에 보관하면 Terraform destroy 이후에도 Import로 손쉽게 복원 가능
- API를 쓰려면 Grafana에서 API Key 생성 → `curl http://localhost:3000/api/dashboards/uid/<UID>`로 JSON 저장 → Import 시 `curl -X POST http://localhost:3000/api/dashboards/db` 사용 (이때 `dashboard` 필드만 남겨 관리)

## 추가 자료
- [Monitoring Best Practices – Prometheus Docs](https://prometheus.io/docs/practices/naming/)
- [Awesome Observability](https://github.com/crazy-canux/awesome-observability)

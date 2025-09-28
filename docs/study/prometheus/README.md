# Prometheus 학습 가이드

## 공식 문서 & 튜토리얼
- [공식 문서](https://prometheus.io/docs/introduction/overview/)
- [PromQL 기본 쿼리 안내](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [표준 메트릭 타입](https://prometheus.io/docs/concepts/metric_types/)
- [식별자 및 레이블](https://prometheus.io/docs/concepts/data_model/)

## 권장 학습 단계
1. Prometheus 구조 및 데이터 모델 이해
2. PromQL 기본 문법 학습 (selectors, operators, functions)
3. Recording rule / alert rule 작성 연습
4. Grafana 등 시각화 도구와 연계

## 참고 자료
- [PromLabs – PromQL Tutorial](https://promlabs.com/promql-cheat-sheet/)
- [awesome-prometheus GitHub](https://github.com/roaldnefs/awesome-prometheus)

## 샘플 리소스
- 노트북: `docs/study/prometheus/promql_quickstart.ipynb`
- 쿼리 파일: `docs/study/prometheus/queries/*.promql`

## 자주 쓰는 PromQL 예시

**CPU 사용률 (최근 30초 평균, %)**

```promql
(1 - avg by (instance)(rate(node_cpu_seconds_total{job="node-exporter", mode="idle"}[30s]))) * 100
```

**메모리 사용률 (%)**

```promql
(1 - node_memory_MemAvailable_bytes{job="node-exporter"} / node_memory_MemTotal_bytes{job="node-exporter"}) * 100
```

**디스크 사용률 (%)**

```promql
(1 - sum by (instance)(node_filesystem_free_bytes{job="node-exporter", fstype!~"tmpfs|overlay"}) / sum by (instance)(node_filesystem_size_bytes{job="node-exporter", fstype!~"tmpfs|overlay"})) * 100
```

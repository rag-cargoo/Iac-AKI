# Prometheus Range Vector 기본 이해

Prometheus 표현식에서 `metric[5m]`처럼 대괄호 안에 기간을 적으면 **Range Vector**가 됩니다. 이는 해당 시점으로부터 지정된 기간 동안 수집된 샘플들의 집합을 의미해요.

예시:
```promql
process_resident_memory_bytes{job="node-exporter"}[1m]
```
이 쿼리를 Prometheus UI의 *Graph* 탭에서 "Execute"하면 테이블(또는 Matrix) 형태로 결과가 표시되죠. 이 화면은 즉시 GUI에서 볼 수 있지만, Grafana 패널이나 Prometheus `query_range` API는 **최종 값으로 Scalar 또는 Instant Vector**를 기대합니다.

## 왜 Grafana에서 에러가 날까?
Grafana 패널은 시간 범위를 지정한 상태에서 Prometheus의 `/api/v1/query_range` 엔드포인트를 호출합니다. 이 API는 Range Vector를 직접 반환하는 쿼리를 허용하지 않아요. 따라서 다음과 같이 Range Vector 표현으로 끝나는 쿼리를 보내면 오류가 납니다.

```promql
process_resident_memory_bytes{job="node-exporter"}[1m]
```

오류 메시지 예:
```
invalid expression type "range vector" for range query, must be Scalar or instant Vector
```

즉, Grafana는 위 표현을 처리할 수 없으니 Range Vector에 `.sum_over_time`, `avg_over_time`, `increase`, `rate`, `irate` 같은 **집계 함수**를 적용해 Instant Vector로 만들어줘야 합니다.

## 올바른 예시
```promql
irate(node_cpu_seconds_total{
  job="node-exporter",
  mode!="idle",
  instance=~"$node"
}[$__rate_interval])
```
`irate(...)` 함수는 Range Vector를 받아서 Instant Vector를 결과로 반환하기 때문에 Grafana에서도 정상적으로 그려집니다.

## 정리
- Range Vector는 Prometheus UI에서 테이블 형태로 관찰할 수 있지만, Grafana 패널에서 그대로 쓰면 안 됩니다.
- `metric[5m]` 형태는 반드시 `rate`, `sum_over_time`, `avg_over_time` 등과 함께 사용해 즉시 벡터나 스칼라로 변환하세요.
- 에러 메시지가 나오면, 쿼리의 마지막이 `[...]`로 끝나고 있는지 확인하고 집계 함수를 감싸면 해결됩니다.

# Prometheus `rate` vs `irate`

Prometheus에서 Counter 값을 시간에 따라 늘어나는 속도로 환산하고 싶을 때 `rate`와 `irate` 두 가지 함수를 많이 사용합니다. 둘 다 입력은 Range Vector (`metric[5m]`)이고, 결과는 Instant Vector지만 구현과 용도가 조금 달라요.

## 공통점
- Counter 유형에만 적용해야 합니다. (`node_cpu_seconds_total`, `http_requests_total` 등)
- 기간 동안 증가량을 초당 단위로 환산합니다.
- `metric[5m]`처럼 Range Vector를 받아 `scalar/s` 형태의 Instant Vector를 돌려줍니다.

## 차이점
| 항목 | `rate` | `irate` |
| --- | --- | --- |
| 계산 구간 | 지정한 범위 전체의 최소제곱선(최적 직선)을 사용 | 가장 최근 두 샘플만으로 계산 |
| 노이즈 대응 | 기간 동안 데이터를 평균화해 변화를 부드럽게 만듦 | 단일 순간의 변화율이라 노이즈에 민감 |
| 사용 시점 | 일반적인 그래프/대시보드, 장기 추세 확인 | 알람이나 순간 급격한 변화 감지, 샘플 간격이 촘촘할 때 |

### `rate`
- 공식: 선형 회귀로 전체 범위의 slope(기울기)를 계산.
- 샘플이 간격을 두고 반복적으로 수집될 때 적절합니다.
- 예시:
  ```promql
  rate(node_cpu_seconds_total{mode="idle"}[5m])
  ```

### `irate`
- 공식: 가장 최근의 두 샘플 `(t1, v1)`과 `(t2, v2)`만으로 `(v2 - v1) / (t2 - t1)` 계산.
- 샘플 간 간격이 매우 짧고, 순간적인 폭주를 감지하고 싶을 때 사용합니다.
- 예시:
  ```promql
  irate(node_cpu_seconds_total{mode="idle"}[1m])
  ```

## 실무 팁
1. **대시보드(추세)**: `rate`를 기본으로 사용하고, 기간은 1분~5분 정도가 일반적입니다.
2. **알람/급변 탐지**: `irate`는 빠른 반응이 필요할 때 사용하되, 샘플 간 간격이 일정하고 충분히 촘촘해야 합니다.
3. **슬로트가 드문 경우**: 샘플 간 간격이 들쭉날쭉한 메트릭에는 `rate`가 안전합니다. `irate`는 샘플이 건너뛰어졌다면 값이 튀거나 0이 나올 수 있습니다.
4. **그래프 확인**: 같은 메트릭으로 `rate`와 `irate`를 동시에 그려 보면 `irate`가 얼마나 변동성이 높은지 쉽게 비교할 수 있습니다.

## 추가 참고
- [Prometheus docs: rate](https://prometheus.io/docs/prometheus/latest/querying/functions/#rate)
- [Prometheus docs: irate](https://prometheus.io/docs/prometheus/latest/querying/functions/#irate)

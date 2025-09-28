# Grafana 학습 가이드

## 공식 문서 & 튜토리얼
- [Grafana Documentation](https://grafana.com/docs/)
- [Dashboard Tutorials](https://grafana.com/tutorials/)
- [Provisioning 가이드](https://grafana.com/docs/grafana/latest/administration/provisioning/)

## 학습 포인트
1. 데이터 소스 연결 (Prometheus 등)
2. 대시보드 구성 요소: 패널, 변수, 템플릿
3. Alerting & Contact Point 설정
4. Provisioning으로 자동화하기

## 템플릿 변수로 노드별 패널 반복하기
1. 대시보드 오른쪽 위 톱니바(⚙️) → **Dashboard settings** → **Variables** → **Add variable**
   - Name: 기존에 쓰고 싶은 변수명(예: `instance`)
   - Type: `Query` / `Label values`
   - Data source: Prometheus
   - Label: `instance`
   - Metric: `up`
   - Label filters: `job = node-exporter`
   - 옵션: `Multi-value`와 `Include All option`을 필요에 따라 활성화
2. 패널 편집에서 PromQL에 `$instance` 변수를 넣습니다. 예)
   ```promql
   (1 - avg(rate(node_cpu_seconds_total{job="node-exporter", mode="idle", instance="$instance"}[30s]))) * 100
   ```
   (변수명을 `node`로 쓰고 싶다면 여기와 아래 Repeat 옵션에서 모두 `$node`로 맞춰 주세요)
3. 패널 설정의 **Repeat options**에서 `Repeat by variable = instance`를 선택하면 노드별 패널이 자동 생성됩니다.
4. `Save dashboard` 후 필요 시 JSON으로 Export하여 백업

### 한 패널에서 여러 노드의 값을 나란히 보고 싶을 때
- PromQL에서 `avg by (instance)` 형태로 그룹을 지정하면 같은 패널 안에서 인스턴스별 라인이 분리됩니다.
- 템플릿 변수를 멀티 선택하거나 `All`을 사용할 경우 `=~`를 써야 합니다. 예)

```promql
100 * (1 - avg by (instance)(rate(node_cpu_seconds_total{mode="idle", instance=~"$node"}[30s])))
```

- All 옵션을 켰다면 `$node`가 자동으로 `.*`로 치환되어 전체 노드가 표시됩니다.

## 참고 자료
- [Grafana Play](https://play.grafana.org/) – 실습용 온라인 Grafana
- [Awesome Grafana](https://github.com/grafana/awesome-grafana)

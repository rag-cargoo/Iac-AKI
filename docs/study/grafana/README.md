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
   - Selection options: `Multi-value`와 `Include All option`을 켜두면 대시보드에서 여러 노드를 동시에 볼 수 있고, `All`을 선택해 전체 노드를 한 번에 표시할 수 있습니다. 커스텀 값이 필요 없으면 `Allow custom values`는 비활성화 상태로 두세요.
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

## 다른 대시보드에서 패널만 가져오기
1. **복사 대상 대시보드**에서 패널 제목 옆 ▼ 메뉴 → **More → Panel JSON**을 선택합니다.
   - `Copy to clipboard` 버튼으로 JSON을 복사하거나 다운로드합니다.
2. **붙여넣을 대시보드**에서 `Add panel → Import`를 고른 뒤 JSON을 붙여 넣으면 동일한 패널이 생성됩니다.
3. 변수를 쓰는 패널이라면 새 대시보드에도 동일한 변수 이름/옵션이 정의돼 있어야 정상 동작합니다.
4. 재사용이 잦다면 패널이나 대시보드를 JSON 파일로 저장해 Git에 관리하고, `Provisioning` 디렉터리를 통해 자동 배포하는 방법도 고려하세요.

## 노드별 패널 반복 가이드
`$node` 변수를 활용한 반복 패널 구성법은 `docs/study/grafana/repeating_node_panels.md` 문서에서 단계별로 다룹니다. 요약하면 변수에 Multi-value/All을 적용한 뒤 동일 패널을 `Repeat by variable = node`로 반복하고, Transformations에서 `Series to rows`와 `Organize fields`를 조합해 CPU·메모리·디스크 지표를 리스트화합니다.

## 참고 자료
- [Grafana Play](https://play.grafana.org/) – 실습용 온라인 Grafana
- [Awesome Grafana](https://github.com/grafana/awesome-grafana)

# Grafana 반복 패널 구성: 노드별 CPU · 메모리 · 디스크

Prometheus에서 가져온 노드 지표를 단일 패널에서 세 줄(CPU Busy, Memory Used, Disk IO Busy)로 보여 주면서, 선택한 각 노드마다 동일한 패널이 자동 생성되도록 구성하는 방법을 정리했습니다. 모든 단계는 Grafana 9 이상을 기준으로 작성되었습니다.

## 1. 대시보드 변수 `$node` 준비
- **Dashboard → Settings → Variables → Add variable**로 이동합니다.
- Type: `Query`, Data source: Prometheus.
- Query: `label_values(node_cpu_seconds_total, instance)` (필요하면 `job="node-exporter"` 같은 라벨 필터를 추가하세요).
- Selection options: `Multi-value`, `Include All option`을 켜고 `All value`는 정규식 전체 매칭용 `.*`로 입력합니다.
- 저장 후 대시보드 상단에 `$node` 드롭다운이 생기고, 여러 인스턴스를 동시에 선택하거나 All 옵션을 사용할 수 있습니다.

## 2. 패널 쿼리 작성
Stat 패널을 하나 만들고 아래 PromQL을 그대로 사용합니다. `$node` 변수는 반복 패널이 주입하는 값으로 치환되며, `=~` 비교를 사용하면 멀티 선택/All에 모두 대응할 수 있습니다.

```promql
(
  label_replace(
    100 * (
      1 - avg by (instance) (
        rate(node_cpu_seconds_total{mode="idle", instance=~"$node"}[$__rate_interval])
      )
    ),
    "metric", "CPU Busy (%)", "instance", ".*"
  )
)
or
(
  label_replace(
    100 * (
      1 - avg by (instance) (
        node_memory_MemAvailable_bytes{instance=~"$node"}
          / node_memory_MemTotal_bytes{instance=~"$node"}
      )
    ),
    "metric", "Memory Used (%)", "instance", ".*"
  )
)
or
(
  label_replace(
    100 * sum by (instance) (
      rate(node_disk_io_time_seconds_total{instance=~"$node"}[$__rate_interval])
    ),
    "metric", "Disk IO Busy (%)", "instance", ".*"
  )
)
```

> 참고: `$__rate_interval`이 빈 값으로 평가되면 쿼리가 실패할 수 있습니다. 이때는 패널의 Query options에서 Min interval을 지정하거나 임시로 `[5m]`같은 고정 범위를 넣어 쿼리를 검증하세요.

## 3. Transformations로 라벨 정리
반복 패널 하나당 CPU/Memory/Disk 세 줄만 남기기 위해 Transformations를 아래 순서로 적용합니다.

1. **Series to rows**: 각 시계열을 `Time`, `instance`, `metric`, `Value` 필드로 풀어냅니다.
2. **Organize fields**: `instance`, `metric`, `Value`만 남기고 이름을 각각 `Instance`, `Metric`, `Usage`로 변경합니다. 필요하면 Metric 오름차순 정렬을 추가해 CPU → Memory → Disk 순으로 정렬합니다.

## 4. 표시 형식 설정
- 패널 유형은 `Stat`, Display → Mode를 `List`로 지정합니다.
- Field options에서 `Usage` 필드를 선택해 Unit을 `percent (0-100)`으로 지정하고, Value options → Reduce는 `Last`로 둡니다.
- Panel Title에 `$node`를 포함하면 반복된 각 패널의 제목이 인스턴스 값을 보여 줍니다.

## 5. 패널 반복 활성화
- Panel → Repeat options → `Repeat by variable`에 `node`를 선택합니다.
- `Max per row` 등 배치 옵션은 대시보드 레이아웃에 맞춰 조정합니다.
- 반복 결과는 편집 화면에서는 보이지 않으므로, 대시보드 보기 모드로 돌아가 `$node` 선택값을 바꾸거나 새로고침해야 패널이 인스턴스별로 생성됩니다.

## 6. N/A 또는 값 누락 시 점검 사항
- `$node` 변수에서 실제 인스턴스를 최소 하나 이상 선택했는지, 혹은 All 선택 시 `.*`가 올바르게 적용되는지 확인합니다.
- Query inspector로 `$__rate_interval`이 실제 숫자 범위로 치환되는지 확인합니다. 실패하면 Min interval 설정을 조정합니다.
- 특정 노드에 해당 메트릭이 없다면 `or vector(0)`을 각 label_replace 블록에 추가해 0으로 치환할 수 있습니다.
- 동일 쿼리로 Table 패널을 만들고 싶다면 Transformations에 `Pivot`을 추가해 행을 Instance, 열을 Metric으로 구성하면 됩니다.

이 과정을 통해 한 번의 쿼리와 구성만으로 선택한 모든 노드에 대해 동일한 패널을 반복 생성할 수 있으며, 각 패널은 세 가지 핵심 지표를 리스트 형태로 명확히 보여줍니다.

## 7. PSI(Pressure Stall) 노드 대시보드 예시
노드 익스포터가 Linux PSI 메트릭(`node_pressure_*`)을 노출하고 있다면, 위 반복 패널 원리를 그대로 활용해 노드별 CPU/메모리/I/O 압력을 빠르게 시각화할 수 있습니다. 아래 설정은 Grafana 9 이상, Prometheus 데이터 소스를 기준으로 작성됐습니다.

### 7.1 템플릿 변수 정의
- **데이터 소스(`ds_prometheus`)**: Type은 `Data source`, Value는 Prometheus 인스턴스. Repeat와는 무관하므로 Multi-value/All 옵션은 비활성화 상태로 둡니다.
- **`job` 변수**  
  - Type: `Query`, Metric: `node_uname_info`, Label: `job`, Label filters는 비움.  
  - `Include All option`을 켜고 `Custom all value`에 `.*`를 입력해 All 선택 시 정규식 전체 매칭이 되도록 합니다. Repeat을 쓰더라도 `job=~"$job"` 비교를 사용하면 All/다중 선택을 안전하게 처리할 수 있습니다.
- **`nodename` 변수**  
  - Query: `label_values(node_uname_info{job=~"$job"}, nodename)`  
  - Multi-value와 Include All을 켜고 All 값은 `.*`로 지정합니다.
- **`node` 변수**  
  - Query: `label_values(node_uname_info{job=~"$job", nodename=~"$nodename"}, instance)`  
  - 반복 패널에서 All도 다루려면 Multi-value/Include All을 켜고 All 값에 `.*`를 지정한 뒤 패널 쿼리에서 `instance=~"$node"`를 사용합니다.  
  - 만약 정규식 비교 없이 `instance="$node"`를 유지하고 싶다면 `node` 변수의 Multi-value/Include All 옵션을 꺼 단일 값만 선택되도록 제한해야 합니다.

### 7.2 패널 쿼리와 반복 설정
2~4개의 패널을 만들어 아래 PromQL을 입력합니다. All 옵션을 지원하려면 `job=~"$job"`, `instance=~"$node"`처럼 정규식 비교를 사용하는 편이 가장 단순합니다.

```promql
irate(node_pressure_cpu_waiting_seconds_total{job=~"$job", instance=~"$node"}[$__rate_interval])
```

```promql
irate(node_pressure_memory_waiting_seconds_total{job=~"$job", instance=~"$node"}[$__rate_interval])
```

```promql
irate(node_pressure_io_waiting_seconds_total{job=~"$job", instance=~"$node"}[$__rate_interval])
```

```promql
irate(node_pressure_irq_stalled_seconds_total{job=~"$job", instance=~"$node"}[$__rate_interval])
```

> 참고: AWS Ubuntu 커널과 같이 `CONFIG_PSI_IRQ`가 비활성화된 환경에서는 `node_pressure_irq_stalled_seconds_total` 자체가 수집되지 않습니다. 이 경우 패널에 `No data`가 뜨는 것이 정상이며, 필요 시 쿼리에 `or vector(0)`을 붙여 0으로 대체할 수 있습니다.

- 패널 제목은 `PSI (CPU/Mem/IO) – [[node]]`처럼 작성하면 Repeat된 각 패널이 노드 값을 그대로 표시합니다.
- **Panel → Repeat options → Repeat by variable**에서 `node`를 선택하면 `$node` 변수에 선택된 값 수만큼 패널이 자동 생성됩니다.

### 7.3 값이 0%만 표시될 때
- PSI는 "대기 시간"을 나타내므로 최근 구간에서 메모리/I/O 압력이 없으면 `irate` 결과가 자연스럽게 0에 가깝습니다. 부하 테스트를 진행하거나 조회 기간을 늘려 값이 변하는지 확인하세요.
- Query inspector로 최종 PromQL을 확인해 `job`과 `instance` 필터가 기대한 값으로 확장됐는지 살펴보세요. All 선택 시 `job=~".*"`, `instance=~".*"` 형태가 보여야 합니다.

이 구성을 통해 대시보드 상단에서 노드를 선택하거나 All로 두더라도, 노드별 패널이 반복 생성되면서 PSI 메트릭 변화를 빠르게 확인할 수 있습니다. 필요하면 Stat 대신 Time series 패널을 사용하거나 Threshold를 추가해 경고 수준을 시각화하세요.

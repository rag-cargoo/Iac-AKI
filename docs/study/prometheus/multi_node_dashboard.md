# PromQL 예시: 모든 노드 CPU/메모리 요약 대시보드

여러 노드를 하나의 Grafana 패널에서 보고 싶을 때는 템플릿 변수를 multi value(`Include All option`)로 설정하고, PromQL에서 정규식 연산자를 사용해야 합니다. `node-exporter` 환경을 기준으로 대표적인 쿼리를 모아 두었습니다.

## 전제 조건
- 변수 `node`: `label_values(up{job="node-exporter"}, instance)`
  - `Include All option`을 켜면 `All` 선택 시 `.*`로 자동 치환됩니다.
- (선택) 변수 `job`: `label_values(up, job)`
  - 해당 job만 필터링하고 싶을 때 사용하세요.

## CPU: 노드별 idle 제외 평균 사용률
```promql
100 * (1 - avg by (instance)(
  rate(node_cpu_seconds_total{
    job=~"$job",
    instance=~"$node",
    mode="idle"
  }[$__rate_interval])
))
```
- `=~` 연산자를 사용해야 `All` 선택 시 정규식이 작동합니다.
- 멀티값일 때는 `avg by (instance)`를 써서 노드별로 라인을 나눕니다.

## CPU: 코어 수 확인
```promql
count(count(node_cpu_seconds_total{
  job=~"$job",
  instance=~"$node"
}) by (cpu, instance)) by (instance)
```
- 노드별 CPU 코어 개수를 볼 수 있는 쿼리입니다.
- `Count(count(...))` 패턴은 `node_exporter`가 CPU 라벨을 `cpu="0"`, `cpu="1"` 식으로 붙여 주기 때문에 자주 쓰입니다.

## CPU: 전체 사용자/시스템/idle 시간 비율
```promql
sum(rate(node_cpu_seconds_total{
  job=~"$job",
  instance=~"$node",
  mode!="idle"
}[$__rate_interval])) by (mode, instance)
```
- Grafana에서 Stacked Area 차트로 보면 각 모드별 비율을 한눈에 볼 수 있습니다.

## Load Average
```promql
node_load1{job=~"$job", instance=~"$node"}
```
- `node_load5`, `node_load15`도 같은 방식으로 추가.

## 메모리 사용량
```promql
(node_memory_MemTotal_bytes{job=~"$job", instance=~"$node"}
 - node_memory_MemAvailable_bytes{job=~"$job", instance=~"$node"})
```
- Grafana 단위를 `bytes (IEC)`로 설정하면 사람이 보기에 편합니다.

## 디스크 사용률
```promql
100 * (1 - node_filesystem_free_bytes{
  job=~"$job",
  instance=~"$node",
  fstype!~"tmpfs|overlay"
} / node_filesystem_size_bytes{
  job=~"$job",
  instance=~"$node",
  fstype!~"tmpfs|overlay"
})
```
- `mountpoint` 라벨로 Repeat 하거나, `Legend`를 `{instance} {device}`로 설정하면 노드별/디바이스별로 구분됩니다.

## 네트워크 송수신
```promql
rate(node_network_receive_bytes_total{job=~"$job", instance=~"$node", device!~"lo"}[$__rate_interval])
rate(node_network_transmit_bytes_total{job=~"$job", instance=~"$node", device!~"lo"}[$__rate_interval])
```
- 패널에 두 개의 쿼리를 넣고 Legend를 `Recv {{instance}} {{device}}`, `Tx {{instance}} {{device}}`처럼 설정하면 됩니다.

## 참고 팁
1. `All` 옵션을 사용할 때는 반드시 `=~"$node"`처럼 정규식 연산자를 사용합니다.
2. 멀티값을 반환하는 변수는 **Legend** 또는 **Repeat** 옵션을 활용해 시각적으로 분리하세요.
3. Gauge 패널에는 `rate/irate`가 아닌 원본 Gauge 값을 사용합니다.
4. 대시보드를 JSON으로 Export해 Git에 보관해 두면 다른 환경에서도 쉽게 재사용할 수 있습니다.

이 파일을 기반으로 필요에 맞게 추가/수정한 뒤 Grafana 패널에 붙여 보세요.

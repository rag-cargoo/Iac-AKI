# 네트워크 및 보안 그룹 강화 과제

## 배경
- `src/iac/terraform/modules/security/main.tf`가 HTTP(80)과 내부 관리 포트를 광범위하게 허용하고 있어 실서비스 수준의 보호가 부족.
- 관측/로그 흐름(Customer 접속, 운영자 접근)에 대한 문서화와 모니터링 설정이 부재.

## 목표
1. 인터넷 노출 트래픽을 Load Balancer 또는 특정 CIDR로 제한한다.
2. 관리 포트(22, 2377, 7946 등)를 원격 운영 IP 또는 보안 그룹 간 통신으로 한정한다.
3. 네트워크 로깅, 알림, 백업 정책을 정의하고 문서화한다.

## 세부 작업
1. **보안 그룹 리팩토링**
   - HTTP(80) 대신 ALB/ELB를 사용하거나, 필수 시 소스 CIDR을 제한.
   - Swarm 노드 간 포트는 self-referencing 대신 전용 보안 그룹을 사용해 세분화.
   - Grafana/Prometheus 등 운영 포트는 VPN/프록시를 통해서만 접근.
2. **퍼블릭 진입점 재설계**
   - ALB/NLB를 Terraform 모듈로 추가하고, Route53/ACM 통합 여부 검토.
   - Bastion 접근은 IP 제한과 MFA/SSO(예: AWS IAM Identity Center) 문서화.
3. **로깅/모니터링**
   - VPC Flow Logs, CloudTrail, Security Hub 통합 여부 검토.
   - CloudWatch Alarms 또는 Grafana Alerts를 통해 비정상 접근 감지 시 알림.
4. **문서 업데이트**
   - 네트워크 다이어그램과 흐름을 `docs/`에 추가.
   - Runbook에서 비상 조치(보안 그룹 잠금, 키 폐기 등)를 정의.
5. **테스트**
   - `terraform plan`으로 변경 영향 확인 후, Stage 환경에서 유효성 검증.
   - Swarm 서비스가 LB 뒤에서 정상 노출되는지, 내부 통신이 유지되는지 확인.

## 검증 체크리스트
- 보안 그룹이 최소 권한 원칙을 준수하도록 모든 인바운드 규칙을 재검토.
- Stage 환경에서 헬스체크와 서비스 접근 테스트를 수행.
- CloudTrail/Flow Logs가 활성화되어 이벤트가 수집되는지 확인.
- 문서 업데이트 후 리뷰어 확인 로그를 남김.

## 참고 문서
- `docs/INFRA_SERVICE_STRUCTURE.md`
- AWS Well-Architected Framework (Security Pillar)

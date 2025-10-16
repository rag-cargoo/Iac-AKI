# AWS Site-to-Site VPN 연결 절차

이 문서는 Lab 02 예제로 생성된 AWS 리소스를 실제 온프레미스 네트워크에 연결하는 과정을 단계별로 요약합니다. Terraform으로 터널까지만 만들면 통신이 되지 않으므로 아래 단계를 모두 수행해야 합니다.

---

## 1. Terraform 실행
1. `terraform.tfvars`에 아래 값을 입력합니다. (예시는 `terraform.tfvars.example` 참고)
   - `customer_gateway_ip`: 고정 공인 IP (예: 218.238.102.217)
   - `vpc_id`: 연결 대상 AWS VPC ID
   - `remote_ipv4_cidrs`: 온프레미스 내부망 CIDR(예: `192.168.35.0/24`)
   - (선택) `route_table_ids`: VPN 경로 전파를 적용할 라우트 테이블 ID
2. Terraform 실행 순서
   ```bash
   make 02-lab-s2svpn-init
   make 02-lab-s2svpn-tf-plan
   make 02-lab-s2svpn-tf-apply
   make 02-lab-s2svpn-tf-output
   ```
3. 출력 값에서 다음을 확인합니다.
   - `vpn_connection_id`
   - `tunnel1_outside_address`, `tunnel2_outside_address`
   - `customer_gateway_id`, `vpn_gateway_id`
   - (선택) `tunnel*_preshared_key` – 직접 지정하지 않았다면 콘솔에서 확인 가능합니다.

---

## 2. AWS 라우팅/보안 설정
Terraform 모듈이 `route_table_ids`를 입력받으면 `aws_vpn_gateway_route_propagation`을 생성합니다. 비워 두었다면 아래 중 하나를 수동으로 설정해야 합니다.

1. **Route Propagation 활성화**
   - VPC 라우트 테이블 콘솔 → "Route propagation" → VPN Gateway 선택 후 Enable
2. **정적 라우트 추가** (route propagation을 사용하지 않는 경우)
   - 각 서브넷 라우트 테이블에 `192.168.35.0/24` → VGW ID(Virtual Private Gateway) 경로를 수동 추가
3. **보안 그룹 / NACL**
   - 온프레미스 CIDR(예: `192.168.35.0/24`)을 허용하도록 SG와 NACL을 조정해야 합니다.

---

## 3. 온프레미스(집) 라우터 구성
VPN 장비 또는 공유기의 관리 콘솔에서 다음 요소를 설정합니다.

1. **터널 생성**
   - 원격 IP: Terraform 출력의 `tunnelX_outside_address`
   - 사전공유키: Terraform에 입력한 값 또는 AWS 콘솔에서 확인한 PSK
   - 암호화/IKE 설정: AWS 권장값(AES256, SHA2, DH 그룹 등)을 사용하면 호환성이 좋습니다.
2. **라우팅**
   - AWS VPC CIDR(예: `10.0.0.0/16`)을 VPN 인터페이스로 향하게 정적 라우트 추가
   - 필요 시 BGP를 사용한다면 `amazon_side_asn`과 `customer_gateway_bgp_asn` 값으로 BGP 세션을 구성합니다.
3. **방화벽 허용**
   - IPsec/IKE(UDP 500, 4500, ESP) 및 실제 서비스 포트를 온프레미스에서 허용합니다.

> 공유기가 IPsec Site-to-Site를 지원하지 않거나 동적 IP만 제공하는 경우 추가 장비가 필요합니다.

---

## 4. 검증
1. AWS EC2 인스턴스 → 온프레 IP
   ```bash
   ping 192.168.35.1
   ```
2. 온프레 PC → AWS VPC 사설 IP
   ```powershell
   ping 10.0.101.10
   ```
3. VPN 터널 상태는 AWS 콘솔(VPN Connections)과 라우터 장비에서 모두 "UP"인지 확인합니다.

---

## 5. WSL까지 연결하고 싶다면?
WSL2는 Windows 내부 NAT 네트워크(예: `172.30.48.0/20`)를 사용하므로 다음 추가 작업이 필요합니다.

1. Windows에서 IP forwarding 활성화:
   ```powershell
   Set-NetIPInterface -InterfaceAlias "Wi-Fi" -Forwarding Enabled
   Set-NetIPInterface -InterfaceAlias "vEthernet (WSL (Hyper-V firewall))" -Forwarding Enabled
   ```
2. Windows 방화벽에서 AWS → WSL 대역으로 들어오는 트래픽 허용
3. 필요 시 `netsh interface portproxy` 등으로 포트 포워딩 또는 RRAS(라우팅 역할) 구성

환경별로 설정이 복잡할 수 있으므로, 먼저 집 LAN ↔ AWS 간 통신이 정상인지 확인하고 WSL 접근은 별도로 설계하는 것을 권장합니다.

---

## 6. 정리 (Terraform destroy)
실습 종료 시 아래 명령으로 리소스를 제거합니다.
```bash
make 02-lab-s2svpn-tf-destroy
```

필요하다면 `make 01-lab-docker-swarm-...` 타깃과 동일하게 루트에서 명령을 호출할 수 있습니다.

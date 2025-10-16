# Lab 02 – AWS Site-to-Site VPN

이 실습은 온프레미스(고정 공인 IP를 가진 라우터)와 AWS VPC 사이에 Site-to-Site VPN을 구성하는 예제입니다. 모든 변수는 `terraform.tfvars`에서만 수정할 수 있도록 설계했습니다.

## 실행 순서

```bash
cd labs/02-lab-s2svpn

# 최초 1회
make tf-init

# 계획 및 적용
make tf-plan
make tf-apply

# 상태 확인
make tf-output

# 종료
make tf-destroy
```

## 필요한 입력 값
`src/terraform/envs/production/terraform.tfvars.example`를 복사하여 `terraform.tfvars`로 사용하고, 다음 값을 환경에 맞게 수정하세요.

- `aws_region` – 리소스를 배포할 리전
- `project_name` – 태깅에 사용되는 이름 접두사
- `vpc_id` – VPN을 연결할 기존 VPC ID
- `customer_gateway_ip` – 온프레미스 게이트웨이의 고정 공인 IP 주소
- `remote_ipv4_cidrs` – 온프레미스 쪽의 방화벽/라우팅에 등록할 프라이빗 CIDR 목록
- `route_table_ids` – (선택) VPN 경로 전파를 적용할 VPC 라우트 테이블 ID. 비워 두면 AWS 콘솔에서 route propagation을 직접 켜거나 정적 경로를 추가해야 합니다.
- `amazon_side_asn` – AWS 측 BGP ASN (Static 라우팅 환경이라도 VPN Gateway 생성 시 필요)
- `customer_gateway_bgp_asn` – 온프레미스 장비의 BGP ASN. Static 라우팅을 사용할 경우 관행적으로 65000 이상 프라이빗 ASN을 입력합니다.

필요하다면 `tunnel1_preshared_key`/`tunnel2_preshared_key`를 직접 지정할 수 있습니다. 값을 생략하면 AWS가 자동 생성합니다(출력으로 확인 가능).

## Terraform 레이아웃

```
src/terraform/
├── modules/
│   └── s2s_vpn/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── envs/
    └── production/
        ├── main.tf
        ├── variables.tf
        └── terraform.tfvars.example
```

모듈을 재사용하고 싶다면 `modules/s2s_vpn`를 다른 환경에서 호출하고, `terraform.tfvars`만 교체하면 됩니다.

- 상세 연결 절차: `docs/setup_guide.md`

## 출력 값
- `vpn_connection_id` – 생성된 VPN 연결 ID
- `customer_gateway_id` – Customer Gateway ID
- `vpn_gateway_id` – Virtual Private Gateway ID
- `tunnel1_outside_address`, `tunnel2_outside_address` – 각 터널의 AWS 측 외부 주소

이 값을 온프레미스 라우터 설정에 반영하여 접속을 완료하세요.

## 추가: 로컬 strongSwan 설치(playbook)

`labs/02-lab-s2svpn/src/ansible/install_strongswan.yml`는 로컬(예: WSL2, 라즈베리파이 등)에서 strongSwan 패키지를 설치하고 서비스를 시작하기 위한 Ansible 플레이북입니다. 이미 설치되어 있다면 아무 작업도 하지 않으므로 idempotent하게 사용할 수 있습니다.

실행 예시:

```bash
ansible-playbook labs/02-lab-s2svpn/src/ansible/install_strongswan.yml -K
```

`-K` 옵션은 sudo 비밀번호가 필요한 경우 입력 받기 위한 것입니다. 서비스명이 배포판에 따라 다를 수 있으므로, 필요하면 vars 섹션이나 service 이름을 조정하세요.

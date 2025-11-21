# StrongSwan Bridged Setup on WSL2

이 문서는 WSL2를 브리지 네트워킹 모드로 전환한 뒤, strongSwan을 사용해 AWS Site-to-Site VPN과 연결하는 절차를 정리합니다. Terraform으로 VPN 리소스를 생성한 뒤 아래 단계를 차례대로 수행하세요.

---

## 1. WSL2 브리지 모드 전환
1. 관리자 PowerShell 실행
2. 다음 명령을 입력합니다.
   ```powershell
   wsl --shutdown
   wsl --networking-mode bridged
   ```
3. WSL을 다시 시작하고 `ip addr`로 새 IP를 확인합니다. (예: `192.168.35.x`)
4. 공유기의 포트포워딩(UDP 500/4500)을 WSL에 할당된 새 IP로 업데이트하세요.

> 브리지 모드를 사용할 수 없는 환경이라면, 강의/문서를 참고해 라우터 또는 별도 리눅스 장비에서 strongSwan을 구동하는 대안을 검토하세요.

---

## 2. Terraform 실행 & 터널 정보 확인
1. 터널 리소스 생성:
   ```bash
   make 02-lab-s2svpn-tf-init
   make 02-lab-s2svpn-tf-plan
   make 02-lab-s2svpn-tf-apply
   ```
2. 출력 값 확인:
   ```bash
   make 02-lab-s2svpn-tf-output
   ```
   - `customer_gateway_id`
   - `vpn_gateway_id`
   - `vpn_connection_id`
   - `tunnel*_outside_address`
3. AWS 콘솔에서 "Download configuration"을 열고 아래 값으로 샘플을 받습니다.
   - 공급업체: `strongswan`
   - 플랫폼: `Ubuntu 16.04`
   - 소프트웨어: `strongswan 5.5.1+`
   - IKE 버전: `ikev1`
   - "샘플 유형 포함"은 기본값 그대로 두면 됩니다. 강제로 체크할 필요 없습니다.
   - 이미 아래 템플릿을 그대로 쓸 거라면 다운로드는 선택 사항입니다. 그래도 AWS가 제시한 암호화 조합, PSK 등을 재확인하려면 샘플을 받아두세요.
4. AWS 라우트 테이블에서 route propagation을 Enable하거나 정적 경로를 추가합니다.
5. Security Group/NACL에서 온프레 CIDR(`192.168.35.0/24`)을 허용해야 합니다.

---

## 3. strongSwan 설치 (WSL 내부)
1. 먼저 IP forwarding이 켜져 있는지 확인합니다.
   ```bash
   sudo sysctl net.ipv4.ip_forward
   ```
   - 값이 `0`이면 `sudo sysctl -w net.ipv4.ip_forward=1`로 즉시 활성화합니다.
   - 영구 적용하려면 아래 명령으로 설정 파일을 만들고, `sudo sysctl --system`으로 다시 로드하세요.
     ```bash
     echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-strongswan.conf >/dev/null
     sudo sysctl --system
     ```
   - WSL은 재시작 시 커널이 초기화되므로, 브리지 모드에서도 위 설정이 유지되는지 필요할 때마다 확인하는 게 안전합니다.
2. 루트 디렉터리에서 Ansible 플레이북 실행:
   ```bash
   make 02-lab-s2svpn-strongswan
   ```
   - 기본으로 sudo 비밀번호를 묻습니다. 비밀번호가 필요 없다면 `ANSIBLE_FLAGS=`로 덮어쓸 수 있습니다.
   - 이미 설치되어 있으면 건너뛰고, 없으면 `strongswan`, `strongswan-pki`, `charon-systemd` 등이 설치됩니다.
3. 설치 직후 strongSwan 서비스 상태를 확인합니다.
   ```bash
   sudo systemctl status strongswan-starter
   sudo ipsec statusall
   ```
   - `active (running)`이면 준비 완료입니다. 실패했다면 로그(`/var/log/syslog`, `journalctl -u strongswan-starter`)를 확인하세요.

---

## 4. strongSwan 구성 파일 수정
1. `/etc/ipsec.conf`에 AWS 콘솔에서 다운로드한 구성 템플릿을 참고하여 터널 설정을 입력합니다.
   - 터널 외부 IP (`tunnel*_outside_address`)
   - 암호화/IKE 파라미터 (AWS 권장값)
   - 로컬/원격 CIDR(`192.168.35.0/24`, AWS VPC CIDR)
   - 예시(실사용 시 X·Y·Z만 실제 CIDR·IP로 치환):
     ```conf
     config setup
       charondebug="ike 1, knl 1, cfg 2"
       uniqueids=no

     conn aws-tunnel-1
       auto=start
       type=tunnel
       keyexchange=ikev1
       authby=psk
       left=%defaultroute
       leftid=@X.X.X.X
       leftsubnet=192.168.35.0/24
       right=Y.Y.Y.Y
       rightid=Y.Y.Y.Y
       rightsubnet=10.0.0.0/16
       ike=aes256-sha1-modp1024!
       esp=aes256-sha1-modp1024!
       ikelifetime=28800s
       lifetime=3600s
       dpddelay=10
       dpdtimeout=30
       dpdaction=restart

     conn aws-tunnel-2
       also=aws-tunnel-1
       right=Z.Z.Z.Z
       rightid=Z.Z.Z.Z
     ```
     `rightsubnet`은 AWS VPC CIDR, `leftsubnet`은 온프레 CIDR에 맞게 수정합니다. AWS 콘솔에서 제공하는 구성 파일에 동일한 구조가 있으므로 값만 정확히 치환하면 됩니다.
   - AWS 콘솔에서 내려받은 구성 파일을 `labs/02-lab-s2svpn/src/run/strongswan/download/`에 복사한 뒤 아래 명령을 실행해 `.local` 파일을 생성합니다.
   ```bash
   make strongswan-generate-local
   ```
     - 기본으로 `src/run/strongswan/templates/ipsec.conf.local`, `.../ipsec.secrets.local`이 만들어져 민감 값은 템플릿과 분리됩니다.
    - `CLONE_ONLY=true make strongswan-generate-local`처럼 실행하면 `.local` 파일을 만들지 않고 생성물만 확인할 수 있습니다.
    - 샘플에 `0.0.0.0/0`이 들어 있다면 `ONPREM_CIDR_OVERRIDE=192.168.35.0/24 AWS_VPC_CIDR_OVERRIDE=10.0.0.0/16 make strongswan-generate-local`처럼 환경 변수를 함께 지정해 원하는 CIDR로 교체할 수 있습니다.
     - 관련 스크립트는 `src/run/strongswan/1-generate-local.sh`에 위치합니다.

   - `/etc`에 반영할 준비가 되면 아래 명령으로 기존 파일을 백업하고 `.local` 내용을 설치합니다.
     ```bash
     make strongswan-install-local
     ```
     명령 안에서 자동으로 sudo를 요청하며, `/etc/ipsec.conf`와 `/etc/ipsec.secrets`는 타임스탬프가 붙은 `.bak` 파일로 백업됩니다.
     - 적용 스크립트는 `src/run/strongswan/2-install-local.sh`입니다.
   - 설치 후 아래 명령으로 strongSwan 서비스를 재시작하고 상태를 확인합니다.
     ```bash
     make strongswan-verify
     ```
     - 검증 스크립트는 `src/run/strongswan/3-verify.sh`로, systemd와 `ipsec` 명령 모두 확인합니다.
2. `/etc/ipsec.secrets`에 사전 공유 키(PSK)를 입력합니다.
   - 예시:
     ```conf
     Y.Y.Y.Y %any : PSK "<터널1_PSK>"
     Z.Z.Z.Z %any : PSK "<터널2_PSK>"
     ```
3. 필요 시 `/etc/ipsec.d/` 경로에 인증서/컴플렉스 설정을 추가할 수 있습니다.
   - 예) AWS가 인증서 기반 구성을 요구한다면 아래처럼 배치합니다.
     ```bash
     sudo install -m 600 customer.key /etc/ipsec.d/private/customer.key
     sudo install -m 644 customer.crt /etc/ipsec.d/certs/customer.crt
     sudo install -m 644 aws-root-ca.crt /etc/ipsec.d/cacerts/aws-root-ca.crt
     ```
   - `ipsec.conf`에는 `leftcert=/etc/ipsec.d/certs/customer.crt`, `rightca=/etc/ipsec.d/cacerts/aws-root-ca.crt` 등으로 참조합니다. PSK만 사용하는 기본 예제라면 이 단계는 건너뛰어도 됩니다.
4. 서비스 재시작:
   ```bash
   sudo ipsec restart
   ```
5. 상태 확인:
   ```bash
   sudo ipsec statusall
   ```

---

## 5. 포트포워딩 및 방화벽 상호 점검
- 공유기 포트포워딩: UDP 500, UDP 4500 → WSL 브리지 IP로 향해야 합니다.
- Windows 방화벽에서도 UDP 500/4500 인바운드를 허용하세요.
- WSL 내부에서 `sudo iptables` 또는 `nftables`로 AWS ↔ 온프레 트래픽을 허용합니다.

---

## 6. 검증
1. **AWS 인스턴스에서 온프레(gateway)로 Ping**
   ```bash
   ping 192.168.35.1
   ```
2. **온프레 PC에서 AWS 사설 IP로 Ping**
   ```powershell
   ping 10.x.x.x
   ```
3. AWS 콘솔의 VPN Connection 상태가 `UP`인지 확인하세요.
4. strongSwan 로그(`/var/log/syslog`, `/var/log/auth.log` 또는 `ipsec statusall`)로 터널 상태를 모니터링합니다.

---

## 7. 정리 (선택)
실습 종료 후 AWS 리소스를 제거하려면:
```bash
make 02-lab-s2svpn-tf-destroy APPLY_FLAGS=-auto-approve
```
strongSwan 설정을 초기화하려면 `/etc/ipsec.conf`, `/etc/ipsec.secrets` 등을 담백하게 복원하거나 백업본을 다시 복원합니다.

---

> 작업 중 변경 사항이나 특이 사항이 있으면 루트의 `CURRENT_PLAN.md`에 메모를 추가해 주세요.

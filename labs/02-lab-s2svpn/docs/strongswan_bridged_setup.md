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
3. AWS 라우트 테이블에서 route propagation을 Enable하거나 정적 경로를 추가합니다.
4. Security Group/NACL에서 온프레 CIDR(`192.168.35.0/24`)을 허용해야 합니다.

---

## 3. strongSwan 설치 (WSL 내부)
1. 루트 디렉터리에서 Ansible 플레이북 실행:
   ```bash
   make 02-lab-s2svpn-strongswan ANSIBLE_FLAGS=-K
   ```
   - 이미 설치되어 있으면 건너뛰고, 없으면 `strongswan`, `strongswan-pki`, `charon-systemd` 등이 설치됩니다.
2. 설치가 끝나면 IP forwarding 및 필요 패키지가 준비된 상태입니다. (WSL 환경에 따라 `sysctl` 적용이 필요할 수 있음)

---

## 4. strongSwan 구성 파일 수정
1. `/etc/ipsec.conf`에 AWS 콘솔에서 다운로드한 구성 템플릿을 참고하여 터널 설정을 입력합니다.
   - 터널 외부 IP (`tunnel*_outside_address`)
   - 암호화/IKE 파라미터 (AWS 권장값)
   - 로컬/원격 CIDR(`192.168.35.0/24`, AWS VPC CIDR)
2. `/etc/ipsec.secrets`에 사전 공유 키(PSK)를 입력합니다.
3. 필요 시 `/etc/ipsec.d/` 경로에 인증서/컴플렉스 설정을 추가할 수 있습니다.
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

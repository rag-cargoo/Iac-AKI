# Current Session Plan

## 시스템 상태 요약
- 작업 브랜치: `labs-refactor`
- Swarm 실습 자산은 `labs/01-lab-docker-swarm/`에 존재하며 정상 동작 확인됨 (`make 01-lab-docker-swarm-run` 완료).
- Site-to-Site VPN 실습(`labs/02-lab-s2svpn/`)의 Terraform 리소스는 모두 삭제한 상태 (`make 02-lab-s2svpn-tf-destroy -auto-approve`).
- WSL2 환경을 브리지 네트워킹으로 전환할 예정이므로, 기존 VPN 리소스 재생성 전에는 다시 apply 하지 않을 것.

## 현재 목표
1. WSL2를 브리지 네트워킹 모드로 전환해 strongSwan을 직접 VPN 게이트웨이로 사용할 수 있도록 준비.
2. 전환 후 공유기 UDP 500/4500 포워딩 대상 IP를 WSL의 새 브리지 IP로 수정.
3. 필요한 라우팅/방화벽 조정 후 strongSwan 설정을 업데이트.
4. Terraform으로 Site-to-Site VPN 리소스를 재생성하고 연결 검증.

## 다음에 해야 할 일 (순서)
1. **WSL 브리지 모드 전환**
   ```powershell
   wsl --shutdown
   wsl --networking-mode bridged
   ```
   - 전환 후 WSL에서 `ip addr`로 새 IP(예: 192.168.35.x)를 확인하고 기록.
2. **네트워크 업데이트**
   - 공유기 포트포워딩: UDP 500/4500 → WSL 새 IP
   - Terraform `remote_ipv4_cidrs`, strongSwan 설정(`
    /etc/ipsec.conf`, `
    /etc/ipsec.secrets`)에 새 로컬 IP 적용.
   - Windows/WSL 방화벽(필요 시) 조정
3. **strongSwan**
   - 설치: `make 02-lab-s2svpn-strongswan ANSIBLE_FLAGS=-K`
   - 설정 파일을 AWS 구성파일에 맞게 채우고 `ipsec restart`
4. **Terraform 재생성**
   ```bash
   make 02-lab-s2svpn-tf-init
   make 02-lab-s2svpn-tf-plan
   make 02-lab-s2svpn-tf-apply
   make 02-lab-s2svpn-tf-output
   ```
   - AWS 라우트 테이블에서 route propagation 또는 정적 경로 확인
5. **검증**
   - AWS 인스턴스 → 온프레 IP, 온프레 PC → AWS 사설 IP Ping 테스트
   - strongSwan 로그, AWS 콘솔에서 터널 상태 확인

## 참고 자료
- `labs/02-lab-s2svpn/docs/setup_guide.md`: Terraform/AWS/strongSwan 설정 흐름 요약
- `labs/02-lab-s2svpn/src/ansible/install_strongswan.yml`: strongSwan 설치 플레이북
- root `Makefile`: `make 02-lab-s2svpn-*` 타깃 모음 (init, plan, apply, output, destroy, strongswan)

## 누락/우려 사항
- WSL 브리지 모드 전환이 Windows 버전(WSL2 최신)에서 지원되는지 확인 필요. 전환에 실패하면 strongSwan을 Windows 자체 또는 별도 리눅스 장비에 구축하는 대안을 검토해야 함.
- BGP를 사용하지 않는 static VPN 구성이라 정적 경로/보안 설정을 수동으로 맞춰야 함 (AWS SG/NACL, 라우터 방화벽 등).

---
문서를 갱신할 때는 날짜와 변경사항을 덧붙여서 유지하세요.

### WSL 버전 관련 메모
- 현재 Windows 11 빌드 26100.6899 (24H2 계열)와 WSL 2.6.1.0 사용 중.
- `ReleaseId`가 2009로 표시되더라도 빌드 번호로 24H2임을 확인.
- `wsl --networking-mode bridged`를 쓰려면 Microsoft Store의 WSL 앱을 최신(프리뷰 포함)으로 업데이트해야 함.
  - 관리자 PowerShell에서 `wsl --update --pre-release`로 업데이트 가능.
  - 또는 Microsoft Store → "Windows Subsystem for Linux" 앱을 직접 업데이트.
- 업데이트 후 `wsl --shutdown` → `wsl --networking-mode bridged` 명령을 다시 실행해 브리지 모드를 활성화할 것.


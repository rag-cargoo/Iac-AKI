# CI/CD 및 거버넌스 강화 과제

## 배경
- ansible-lint, terraform validate, pre-commit 훅이 아직 구성되지 않아 수동 검증에 의존.
- CI 파이프라인(`.github/`, `ci/`)이 없고, 문서에서도 자동화 절차가 미정.

## 목표
1. 기본 품질 게이트(Formatting, Lint, Plan 검증)를 자동화한다.
2. PR 템플릿과 체크리스트를 정비해 Terraform/Ansible 변경 사항을 명확히 보고한다.
3. 비밀/민감 데이터 커밋을 차단하는 정책을 수립한다.

## 세부 작업
1. **pre-commit 구성**
   - `pre-commit` 설정 파일을 추가해 `terraform fmt`, `terraform validate`, `ansible-lint`, `yamllint`, `shellcheck` 등을 실행.
   - 문서에 설치/사용법(`make hooks` 등)을 안내.
2. **CI 파이프라인 구축**
   - GitHub Actions 또는 원하는 CI 도구에서 Terraform `plan`, Ansible `--syntax-check`, lint 작업을 병렬로 수행한다.
   - main 브랜치 머지 전 인간 승인 단계를 포함하도록 워크플로 설계.
3. **PR/커밋 정책**
   - `.github/PULL_REQUEST_TEMPLATE.md` 또는 `docs/process/`에 Terraform Plan 첨부, Ansible 실행 로그 공유 등 요구사항 추가.
   - Conventional Commits 준수 여부를 자동 체크할지 검토.
4. **비밀 관리**
   - git-secrets, trufflehog 등 검사 도구를 도입.
   - CI에서 비밀 유출 감지 시 빌드 실패 및 알림.
5. **문서화**
   - `AGENTS.md`와 `docs/REAL_WORLD_STRUCTURE.md`에 강화된 파이프라인과 검증 단계 업데이트.
   - 신규 팀원 온보딩 가이드를 추가.

## 검증 체크리스트
- 로컬에서 `pre-commit run --all-files`가 성공하는지 확인.
- PR 생성 시 자동으로 Terraform plan/artifact가 첨부되는지 확인.
- CI 로그에 ansible-lint/terraform validate 결과가 기록되는지 검증.
- 비밀 검출 도구가 테스트 문자열에 대해 경고를 발생시키는지 테스트.

## 참고 문서
- `docs/REAL_WORLD_STRUCTURE.md`
- `AGENTS.md`

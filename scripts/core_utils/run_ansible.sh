#!/usr/bin/env bash
set -e

# 프로젝트 루트 기준 상대경로 계산
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts/core_utils"
ANSIBLE_DIR="$PROJECT_ROOT/Iac/ANSIBLE"

# 1️⃣ 환경 변수 로드
source "$SCRIPTS_DIR/setup_project_env.sh"

# 2️⃣ Ansible 플레이북 실행
cd "$ANSIBLE_DIR"
ansible-playbook \
  -i "$SCRIPTS_DIR/dynamic_inventory.py" \
  playbook.yml \
  --private-key="$SSH_KEY_PATH"

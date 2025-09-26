#!/bin/sh
# --------------------------------------------------------------------
# 2025-09-26 swarm prompt installer
# 목적: ~/.bashrc에 Docker Swarm 프롬프트 태그([swarm]) 블록을 추가
# 동작: 마커가 이미 있으면 변경 없이 종료, 없으면 블록을 append
# 사용: scripts/tools/install_swarm_prompt.sh && source ~/.bashrc
# --------------------------------------------------------------------
set -eu

TARGET="$HOME/.bashrc"
MARKER="# 2025-09-26 Docker Swarm prompt marker"

if [ ! -f "$TARGET" ]; then
  echo "error: cannot find $TARGET" >&2
  exit 1
fi

if grep -qF "$MARKER" "$TARGET"; then
  echo "Swarm prompt marker already present in $TARGET."
  echo "Run 'source ~/.bashrc' to reload the prompt."
  exit 0
fi

cat <<'SNIPPET' >> "$TARGET"

# --------------------------------------------------------------------
# 2025-09-26 Docker Swarm prompt marker
# 목적: DOCKER_HOST가 원격 Swarm(manager)으로 설정됐을 때 프롬프트에
#        짧은 태그([swarm])를 표시해 로컬/원격 컨텍스트를 구분
# --------------------------------------------------------------------
if [ -z "${ORIGINAL_PS1+x}" ]; then
  ORIGINAL_PS1="$PS1"
fi

_docker_swarm_prompt_tag() {
  if [ -n "$DOCKER_HOST" ]; then
    printf '[swarm] '
  fi
}

_docker_swarm_prompt_apply() {
  PS1="$(_docker_swarm_prompt_tag)${ORIGINAL_PS1}"
}

PROMPT_COMMAND="_docker_swarm_prompt_apply${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
# --------------------------------------------------------------------
# End of Docker Swarm prompt marker (2025-09-26)
# --------------------------------------------------------------------

SNIPPET

chmod 600 "$TARGET"

echo "Swarm prompt marker appended to $TARGET."
echo "Run 'source ~/.bashrc' to apply the change."

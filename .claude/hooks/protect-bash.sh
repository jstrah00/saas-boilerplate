#!/usr/bin/env bash
# PreToolUse hook for Bash tool calls. Reads JSON from stdin, exits 2 with a
# message on stderr to block destructive commands. Exit 0 allows the call.
set -euo pipefail

input=$(cat)
command=$(printf '%s' "$input" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("tool_input",{}).get("command",""))')

reject() {
  printf 'BLOCKED by protect-bash.sh: %s\n' "$1" >&2
  exit 2
}

case "$command" in
  *'rm -rf /'*|*'rm -rf ~'*|*'rm -rf $HOME'*|*'rm -rf .'*) reject "rm -rf against root, home, or current dir" ;;
  *'git push --force '*|*'git push -f '*|*'git push --force'*) reject "force push without --force-with-lease — confirm with the user first" ;;
  *'git reset --hard'*) reject "git reset --hard discards work — investigate the underlying issue instead" ;;
  *'git clean -fd'*|*'git clean -fdx'*) reject "git clean -fd may delete user work — confirm first" ;;
  *':(){ :|:& };:'*) reject "fork bomb" ;;
  *'sudo rm '*) reject "sudo rm — never run via Claude" ;;
  *'mkfs.'*|*'mkfs '*) reject "filesystem creation" ;;
  *' > /dev/sda'*|*' > /dev/nvme'*) reject "raw disk write" ;;
  *'dd if='*'of=/dev/'*) reject "dd to a device node" ;;
esac

if [[ -n "${PROD_HOST:-}" && "$command" == *"$PROD_HOST"* ]]; then
  reject "command targets production host \$PROD_HOST=$PROD_HOST"
fi

exit 0

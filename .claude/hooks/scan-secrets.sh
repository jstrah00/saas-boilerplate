#!/usr/bin/env bash
# UserPromptSubmit hook: block prompts that contain obvious secrets.
# Exit 2 with a stderr message to block; exit 0 to allow.
set -euo pipefail

input=$(cat)
prompt=$(printf '%s' "$input" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("prompt",""))')

reject() {
  printf 'BLOCKED by scan-secrets.sh: prompt contains a likely secret (%s). Redact before resending.\n' "$1" >&2
  exit 2
}

match() {
  # Returns 0 if pattern matches the prompt, 1 otherwise.
  printf '%s' "$prompt" | grep -Eq -- "$1"
}

if match 'AKIA[0-9A-Z]{16}'; then reject "AWS access key id"; fi
if match '\b(sk|pk|rk)_live_[0-9a-zA-Z]{24,}'; then reject "Stripe live key"; fi
if match 'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'; then reject "JWT token"; fi
if match '[0-9]{8,12}:[A-Za-z0-9_-]{30,}'; then reject "Telegram bot token"; fi
if match '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'; then reject "PEM private key"; fi
if match '\bghp_[A-Za-z0-9]{36}\b|\bgithub_pat_[A-Za-z0-9_]{82}\b'; then reject "GitHub token"; fi
if match '\bxox[abprs]-[A-Za-z0-9-]{10,}\b'; then reject "Slack token"; fi

exit 0

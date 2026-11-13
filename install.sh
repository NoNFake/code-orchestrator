#!/usr/bin/env bash
# Install architect/coder/tester agents for opencode and/or fuckcode.
# Local:  ./install.sh
# Remote: curl -fsSL https://raw.githubusercontent.com/NoNFake/code-orchestrator/main/install.sh | bash
set -euo pipefail

agents=(orchestrator.md coder.md tester.md)
raw="${CODE_ORCHESTRATOR_RAW:-https://raw.githubusercontent.com/NoNFake/code-orchestrator/main/.opencode/agents}"
raw="${raw%/}"

self="${BASH_SOURCE[0]:-}"
work=""
if [ -n "$self" ] && [ -f "$self" ]; then
  work="$(cd "$(dirname "$self")" && pwd)/.opencode/agents"
else
  command -v curl >/dev/null 2>&1 || { echo "error: curl is required" >&2; exit 1; }
  work="$(mktemp -d)"
  trap 'rm -rf "$work"' EXIT
  for name in "${agents[@]}"; do
    curl -fsSL "$raw/$name" -o "$work/$name" \
      || { echo "error: failed to download $name" >&2; exit 1; }
  done
fi

config="${XDG_CONFIG_HOME:-$HOME/.config}"
found=0

for tool in opencode fuckcode; do
  command -v "$tool" >/dev/null 2>&1 || { echo "skip: $tool not in PATH"; continue; }
  found=1
  dir="$config/$tool/agents"
  mkdir -p "$dir"

  for name in "${agents[@]}"; do
    file="$work/$name"
    [ -f "$file" ] || { echo "error: missing $file" >&2; exit 1; }
    dest="$dir/$name"

    if [ -e "$dest" ] && ! cmp -s "$file" "$dest"; then
      backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
      cp -pL "$dest" "$backup"
      echo "backup: $backup"
    fi

    rm -f "$dest"
    cp "$file" "$dest"
    chmod 644 "$dest"
    echo "installed: $dest"
  done
done

[ "$found" -eq 1 ] || { echo "error: neither opencode nor fuckcode found in PATH" >&2; exit 1; }

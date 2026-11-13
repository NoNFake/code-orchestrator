#!/usr/bin/env bash
# Ставит агентов глобально: ~/.config/opencode/agents (и fuckcode, если он есть).
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.opencode/agents"
[[ -d "$src" ]] || { echo "нет каталога агентов: $src" >&2; exit 1; }

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
roots=("$config_home/opencode")
[[ -d "$config_home/fuckcode" ]] && roots+=("$config_home/fuckcode")

for root in "${roots[@]}"; do
  dest="$root/agents"
  mkdir -p "$dest"
  for file in "$src"/*.md; do
    target="$dest/$(basename "$file")"
    # Не затираем чужие файлы с тем же именем.
    if [[ -e "$target" && ! -L "$target" ]]; then
      echo "пропуск $(basename "$file"): $target уже существует и не является ссылкой" >&2
      continue
    fi
    ln -sfn "$file" "$target"
    echo "ok: $target"
  done
done

echo
echo "Готово. Чтобы оркестратор был агентом по умолчанию, добавьте в"
echo "$config_home/opencode/opencode.jsonc:"
echo '  "default_agent": "orchestrator"'

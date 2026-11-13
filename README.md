# code-orchestrator

Схема **архитектор → исполнитель → проверяющий** для [OpenCode](https://opencode.ai) и FuckCode v2.

Дорогая модель планирует, ставит ТЗ и ревьюит diff. Дешёвые субагенты в изолированных
сессиях пишут код и гоняют тесты. Мусор от промежуточных попыток не забивает контекст
оркестратора, а лимиты дорогой модели не тратятся на рутину.

| Агент | Режим | Роль | Права |
| --- | --- | --- | --- |
| `orchestrator` | primary | разведка, декомпозиция, ТЗ, ревью diff | без edit/write; субагенты только `coder` и `tester` |
| `coder` | subagent | правит код строго по ТЗ | edit, shell |
| `tester` | subagent | сборка, типы, линтер, тесты | shell, read; без edit |

`edit` у оркестратора запрещён на уровне прав, а не на честном слове: даже правку в одну
строку выполняет `coder`, а оркестратор проверяет результат.

## Требования

- OpenCode v2+ или FuckCode v2+ (в v1 другой формат агентов).
- Настроенный провайдер моделей и доступ к дешёвой модели для воркеров.

## Установка

### Глобально (для всех проектов)

```bash
git clone <ваш-репозиторий> ~/code-orchestrator
cd ~/code-orchestrator
./install.sh
```

Скрипт создаёт симлинки в `~/.config/opencode/agents/` (и в `~/.config/fuckcode/agents/`,
если каталог существует). Чужие файлы с теми же именами не перезаписываются.
Обновление — `cd ~/code-orchestrator && git pull`: симлинки подхватят изменения.

Чтобы новая сессия сразу открывалась в оркестраторе, добавьте в
`~/.config/opencode/opencode.jsonc`:

```jsonc
{
  "default_agent": "orchestrator"
}
```

### В конкретный проект

```bash
mkdir -p /path/to/project/.opencode
cp -r .opencode/agents /path/to/project/.opencode/
```

Агенты подхватятся при запуске `opencode` в этом проекте. Оркестратор по умолчанию
включается тем же `"default_agent": "orchestrator"` в `opencode.jsonc` проекта.

## Модели

По умолчанию субагенты наследуют модель родителя, то есть дорогую. Задайте воркерам
дешёвую модель — в frontmatter агента:

```yaml
---
description: Implementer: writes and edits code strictly to the orchestrator's spec
mode: subagent
model: opencode-go/deepseek-v4.1-flash
---
```

или в `opencode.jsonc` (не в двух местах сразу):

```jsonc
"agents": {
  "coder":  { "model": "opencode-go/deepseek-v4.1-flash" },
  "tester": { "model": "opencode-go/claude-haiku-5-5" }
}
```

Префикс провайдера и имя модели возьмите из списка:

```bash
opencode models
```

## Использование

Запустите `opencode` в проекте и выберите агента `orchestrator` (или `default_agent`
из установки выше). Дальше просто ставьте задачу:

```text
Почини падение checkout при пустой корзине и добавь регрессионный тест.
```

Что произойдёт:

1. Оркестратор прочитает нужные файлы и разобьёт задачу на шаги.
2. Запустит `coder` с точным ТЗ: пути, сигнатуры, краевые случаи.
3. Посмотрит `git diff`, при необходимости запустит `tester`.
4. Вернёт задачу на доработку или закроет её с коротким отчётом.

Независимые модули можно делать параллельно: оркестратор запускает несколько `coder`
одновременно, каждый в своей сессии.

## Структура

```text
.opencode/agents/
├── orchestrator.md   # primary: промпт и права техлида
├── coder.md          # subagent: промпт исполнителя
└── tester.md         # subagent: промпт проверяющего
opencode.jsonc        # default_agent и пример назначения моделей
install.sh            # глобальная установка симлинками
```

Агенты — обычный Markdown с YAML-frontmatter: `description`, `mode`, `model`,
`permissions`. Промпты написаны на английском — модели точнее следуют инструкциям.
Правьте их под свой проект, это и есть вся настройка.

## Удаление

```bash
rm ~/.config/opencode/agents/{orchestrator,coder,tester}.md
```

Если ставили через `install.sh` и у вас есть FuckCode — те же ссылки в
`~/.config/fuckcode/agents/`.

И уберите `default_agent` из глобального `opencode.jsonc`, если добавляли.

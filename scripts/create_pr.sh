#!/usr/bin/env bash
# Cria (ou atualiza) um pull request no GitHub a partir da branch atual,
# com uma seção "## Commits" gerada automaticamente no corpo, listando
# todo commit entre a branch base e a atual.
#
# Se já existir um PR pra essa branch, o script atualiza só a seção de
# commits (sem apagar o resto da descrição que já estiver lá).
#
# Uso:
#   scripts/create_pr.sh [branch_base] [-- flags extras pro "gh pr create"/"gh pr edit"]
#
# Exemplos:
#   scripts/create_pr.sh                                 # PR pra main, título auto (--fill)
#   scripts/create_pr.sh develop                          # PR pra develop em vez de main
#   scripts/create_pr.sh main -- --draft                  # cria como draft
#   scripts/create_pr.sh main -- --title "Meu título"     # título customizado

set -euo pipefail

BASE_BRANCH="${1:-main}"
shift || true
if [ "${1:-}" = "--" ]; then
  shift
fi
EXTRA_ARGS=("$@")

CURRENT_BRANCH=$(git branch --show-current)

if [ -z "$CURRENT_BRANCH" ]; then
  echo "Erro: não foi possível detectar a branch atual (HEAD destacado?)." >&2
  exit 1
fi

if [ "$CURRENT_BRANCH" = "$BASE_BRANCH" ]; then
  echo "Erro: você está na própria branch base ($BASE_BRANCH). Troque para a branch de feature antes de rodar." >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "Erro: gh (GitHub CLI) não encontrado no PATH." >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Erro: gh não está autenticado. Rode: gh auth login" >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "Aviso: há alterações não commitadas — elas NÃO entram no PR (só o que já foi commitado)." >&2
fi

echo "Enviando '$CURRENT_BRANCH' para o remoto..."
git push -u origin "$CURRENT_BRANCH"

COMMIT_LIST=$(git log --reverse --pretty=format:'- %s (`%h`)' "${BASE_BRANCH}..${CURRENT_BRANCH}")

if [ -z "$COMMIT_LIST" ]; then
  echo "Erro: nenhum commit novo entre $BASE_BRANCH e $CURRENT_BRANCH." >&2
  exit 1
fi

BODY_FILE=$(mktemp)
trap 'rm -f "$BODY_FILE"' EXIT

EXISTING_PR_URL=$(gh pr view "$CURRENT_BRANCH" --json url --jq .url 2>/dev/null || true)

if [ -n "$EXISTING_PR_URL" ]; then
  echo "Já existe um PR pra essa branch — atualizando a seção de commits: $EXISTING_PR_URL"

  # Mantém tudo que já estava na descrição ANTES de uma seção "## Commits"
  # (se existir uma de uma execução anterior deste script), e substitui só ela.
  EXISTING_BODY=$(gh pr view "$CURRENT_BRANCH" --json body --jq .body)
  SUMMARY=$(printf '%s\n' "$EXISTING_BODY" | awk '/^## Commits$/{exit} {print}')

  {
    printf '%s\n' "$SUMMARY"
    echo
    echo "## Commits"
    echo
    echo "$COMMIT_LIST"
  } > "$BODY_FILE"

  gh pr edit "$CURRENT_BRANCH" --body-file "$BODY_FILE" "${EXTRA_ARGS[@]}"
  echo "$EXISTING_PR_URL"
else
  echo "Criando pull request: $CURRENT_BRANCH -> $BASE_BRANCH"

  {
    echo "## Commits"
    echo
    echo "$COMMIT_LIST"
  } > "$BODY_FILE"

  gh pr create --base "$BASE_BRANCH" --head "$CURRENT_BRANCH" --fill --body-file "$BODY_FILE" "${EXTRA_ARGS[@]}"
fi

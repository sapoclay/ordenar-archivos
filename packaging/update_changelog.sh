#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHANGELOG_FILE="${ROOT_DIR}/debian/changelog"
VERSION="${1:-}"
MESSAGE="${2:-__AUTO__}"
MAINTAINER_NAME="${MAINTAINER_NAME:-$(git config user.name 2>/dev/null || echo Usuario)}"
MAINTAINER_EMAIL="${MAINTAINER_EMAIL:-$(git config user.email 2>/dev/null || echo usuario@localhost)}"

if [[ -z "$VERSION" ]]; then
  echo "Uso: $0 <version> [mensaje]" >&2
  exit 1
fi

construir_items_desde_git() {
  if ! command -v git >/dev/null 2>&1 || ! git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 1
  fi

  local previo_version=""
  if [[ -f "$CHANGELOG_FILE" ]]; then
    previo_version="$(sed -n '1s/^ordenar-archivos (\([^)]*\)).*/\1/p' "$CHANGELOG_FILE")"
  fi

  local rango=""
  if [[ -n "$previo_version" ]]; then
    if git -C "$ROOT_DIR" rev-parse -q --verify "refs/tags/v${previo_version}" >/dev/null; then
      rango="v${previo_version}..HEAD"
    elif git -C "$ROOT_DIR" rev-parse -q --verify "refs/tags/${previo_version}" >/dev/null; then
      rango="${previo_version}..HEAD"
    fi
  fi

  if [[ -n "$rango" ]]; then
    git -C "$ROOT_DIR" log "$rango" --no-merges --pretty='  * %s' --reverse | sed '/^  \* $/d'
  else
    git -C "$ROOT_DIR" log -n 10 --no-merges --pretty='  * %s' --reverse | sed '/^  \* $/d'
  fi
}

mkdir -p "$(dirname "$CHANGELOG_FILE")"

CHANGELOG_ITEMS=""
if [[ "$MESSAGE" == "__AUTO__" || "$MESSAGE" == "auto" || "$MESSAGE" == "AUTO" ]]; then
  if ! CHANGELOG_ITEMS="$(construir_items_desde_git)" || [[ -z "${CHANGELOG_ITEMS// /}" ]]; then
    CHANGELOG_ITEMS="  * Actualización de versión."
  fi
else
  CHANGELOG_ITEMS="  * ${MESSAGE}"
fi

TMP_FILE="$(mktemp)"
{
  echo "ordenar-archivos (${VERSION}) unstable; urgency=medium"
  echo
  printf '%s\n' "$CHANGELOG_ITEMS"
  echo
  echo " -- ${MAINTAINER_NAME} <${MAINTAINER_EMAIL}>  $(date -R)"
  echo
  if [[ -f "$CHANGELOG_FILE" ]]; then
    cat "$CHANGELOG_FILE"
  fi
} > "$TMP_FILE"

mv "$TMP_FILE" "$CHANGELOG_FILE"
echo "Changelog actualizado en ${CHANGELOG_FILE}"

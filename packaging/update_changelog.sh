#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHANGELOG_FILE="${ROOT_DIR}/debian/changelog"
VERSION="${1:-}"
MESSAGE="${2:-Actualización de versión.}"
MAINTAINER_NAME="${MAINTAINER_NAME:-$(git config user.name 2>/dev/null || echo Usuario)}"
MAINTAINER_EMAIL="${MAINTAINER_EMAIL:-$(git config user.email 2>/dev/null || echo usuario@localhost)}"

if [[ -z "$VERSION" ]]; then
  echo "Uso: $0 <version> [mensaje]" >&2
  exit 1
fi

mkdir -p "$(dirname "$CHANGELOG_FILE")"

TMP_FILE="$(mktemp)"
{
  echo "ordenar-archivos (${VERSION}) unstable; urgency=medium"
  echo
  echo "  * ${MESSAGE}"
  echo
  echo " -- ${MAINTAINER_NAME} <${MAINTAINER_EMAIL}>  $(date -R)"
  echo
  if [[ -f "$CHANGELOG_FILE" ]]; then
    cat "$CHANGELOG_FILE"
  fi
} > "$TMP_FILE"

mv "$TMP_FILE" "$CHANGELOG_FILE"
echo "Changelog actualizado en ${CHANGELOG_FILE}"

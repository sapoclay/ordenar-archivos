#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-}"
MESSAGE="${2:-__AUTO__}"
PKG_NAME="ordenar-archivos"
CHANGELOG_FILE="${ROOT_DIR}/debian/changelog"
DIST_DEB="${ROOT_DIR}/dist/${PKG_NAME}_${VERSION}_all.deb"
FORCE_RELEASE="${FORCE_RELEASE:-0}"

if [[ -z "$VERSION" ]]; then
  echo "Uso: $0 <version> [mensaje_changelog]" >&2
  exit 1
fi

if [[ "$FORCE_RELEASE" != "1" ]]; then
  if [[ -f "$CHANGELOG_FILE" ]] && grep -Eq "^${PKG_NAME} \(${VERSION}\) " "$CHANGELOG_FILE"; then
    echo "Error: la versión ${VERSION} ya existe en ${CHANGELOG_FILE}." >&2
    echo "Usa otra versión o fuerza con: FORCE_RELEASE=1 $0 ${VERSION} \"${MESSAGE}\"" >&2
    exit 2
  fi

  if [[ -f "$DIST_DEB" ]]; then
    echo "Error: ya existe el artefacto ${DIST_DEB}." >&2
    echo "Usa otra versión o fuerza con: FORCE_RELEASE=1 $0 ${VERSION} \"<mensaje-opcional>\"" >&2
    exit 3
  fi
fi

"${ROOT_DIR}/packaging/update_changelog.sh" "$VERSION" "$MESSAGE"
"${ROOT_DIR}/packaging/build_deb.sh" "$VERSION"

echo
echo "Release completada: dist/ordenar-archivos_${VERSION}_all.deb"

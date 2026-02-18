#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
DIST_DIR="${ROOT_DIR}/dist"
VERSION="${1:-1.0.0}"
PKG_NAME="ordenar-archivos"
PKG_ROOT="${BUILD_DIR}/${PKG_NAME}_${VERSION}_all"
MAINTAINER_NAME="${MAINTAINER_NAME:-$(git config user.name 2>/dev/null || echo Usuario)}"
MAINTAINER_EMAIL="${MAINTAINER_EMAIL:-$(git config user.email 2>/dev/null || echo usuario@localhost)}"
PKG_HOMEPAGE="${PKG_HOMEPAGE:-https://github.com/sapoclay/ordenar-archivos}"
PKG_SHORT_DESC="${PKG_SHORT_DESC:-Ordena archivos por extensión, fecha, inicial y permite deshacer}"
PKG_LONG_DESC="${PKG_LONG_DESC:-Aplicación para Ubuntu que añade opciones de ordenado en el clic derecho de varios gestores de archivos (Nautilus, Nemo, Caja y Dolphin).}"
DEBIAN_CHANGELOG_SOURCE="${ROOT_DIR}/debian/changelog"

rm -rf "${PKG_ROOT}"
mkdir -p "${PKG_ROOT}/DEBIAN"
mkdir -p "${PKG_ROOT}/usr/bin"
mkdir -p "${PKG_ROOT}/usr/share/nautilus/scripts"
mkdir -p "${PKG_ROOT}/usr/share/nautilus-python/extensions"
mkdir -p "${PKG_ROOT}/usr/share/nemo/scripts"
mkdir -p "${PKG_ROOT}/usr/share/caja/scripts"
mkdir -p "${PKG_ROOT}/usr/share/kio/servicemenus"
mkdir -p "${PKG_ROOT}/usr/share/doc/${PKG_NAME}"

cat > "${PKG_ROOT}/DEBIAN/control" <<EOF
Package: ${PKG_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: all
Maintainer: ${MAINTAINER_NAME} <${MAINTAINER_EMAIL}>
Homepage: ${PKG_HOMEPAGE}
Depends: python3, python3-nautilus
Recommends: libnotify-bin
Description: ${PKG_SHORT_DESC}
 ${PKG_LONG_DESC}
EOF

install -m 0755 "${ROOT_DIR}/bin/ordenar_por_extension.py" "${PKG_ROOT}/usr/bin/ordenar-por-extension"
install -m 0755 "${ROOT_DIR}/bin/ordenar_contextual.sh" "${PKG_ROOT}/usr/bin/ordenar-contextual.sh"
install -m 0755 "${ROOT_DIR}/bin/nautilus_ordenar_extension.py" "${PKG_ROOT}/usr/share/nautilus-python/extensions/ordenar_por_extension.py"
install -m 0755 "${ROOT_DIR}/bin/instalar_accion_thunar.py" "${PKG_ROOT}/usr/bin/ordenar-instalar-thunar"
install -m 0755 "${ROOT_DIR}/bin/desinstalar_accion_thunar.py" "${PKG_ROOT}/usr/bin/ordenar-desinstalar-thunar"

cat > "${PKG_ROOT}/usr/share/nautilus/scripts/Ordenar por extensiones" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/ordenar-contextual.sh --modo extension "$@"
EOF
chmod 0755 "${PKG_ROOT}/usr/share/nautilus/scripts/Ordenar por extensiones"

cat > "${PKG_ROOT}/usr/share/nautilus/scripts/Ordenar por fecha" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/ordenar-contextual.sh --modo fecha "$@"
EOF
chmod 0755 "${PKG_ROOT}/usr/share/nautilus/scripts/Ordenar por fecha"

cat > "${PKG_ROOT}/usr/share/nautilus/scripts/Ordenar por inicial" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/ordenar-contextual.sh --modo inicial "$@"
EOF
chmod 0755 "${PKG_ROOT}/usr/share/nautilus/scripts/Ordenar por inicial"

cat > "${PKG_ROOT}/usr/share/nautilus/scripts/Deshacer última ordenación" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/ordenar-contextual.sh --modo deshacer "$@"
EOF
chmod 0755 "${PKG_ROOT}/usr/share/nautilus/scripts/Deshacer última ordenación"

cat > "${PKG_ROOT}/usr/share/nemo/scripts/Ordenar por extensiones" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/ordenar-contextual.sh --modo extension "$@"
EOF
chmod 0755 "${PKG_ROOT}/usr/share/nemo/scripts/Ordenar por extensiones"

cat > "${PKG_ROOT}/usr/share/nemo/scripts/Ordenar por fecha" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/ordenar-contextual.sh --modo fecha "$@"
EOF
chmod 0755 "${PKG_ROOT}/usr/share/nemo/scripts/Ordenar por fecha"

cat > "${PKG_ROOT}/usr/share/nemo/scripts/Ordenar por inicial" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/ordenar-contextual.sh --modo inicial "$@"
EOF
chmod 0755 "${PKG_ROOT}/usr/share/nemo/scripts/Ordenar por inicial"

cat > "${PKG_ROOT}/usr/share/nemo/scripts/Deshacer última ordenación" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/ordenar-contextual.sh --modo deshacer "$@"
EOF
chmod 0755 "${PKG_ROOT}/usr/share/nemo/scripts/Deshacer última ordenación"

cat > "${PKG_ROOT}/usr/share/caja/scripts/Ordenar por extensiones" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/ordenar-contextual.sh --modo extension "$@"
EOF
chmod 0755 "${PKG_ROOT}/usr/share/caja/scripts/Ordenar por extensiones"

cat > "${PKG_ROOT}/usr/share/caja/scripts/Ordenar por fecha" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/ordenar-contextual.sh --modo fecha "$@"
EOF
chmod 0755 "${PKG_ROOT}/usr/share/caja/scripts/Ordenar por fecha"

cat > "${PKG_ROOT}/usr/share/caja/scripts/Ordenar por inicial" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/ordenar-contextual.sh --modo inicial "$@"
EOF
chmod 0755 "${PKG_ROOT}/usr/share/caja/scripts/Ordenar por inicial"

cat > "${PKG_ROOT}/usr/share/caja/scripts/Deshacer última ordenación" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/ordenar-contextual.sh --modo deshacer "$@"
EOF
chmod 0755 "${PKG_ROOT}/usr/share/caja/scripts/Deshacer última ordenación"

cat > "${PKG_ROOT}/usr/share/kio/servicemenus/ordenar-por-extension.desktop" <<'EOF'
[Desktop Entry]
Type=Service
X-KDE-ServiceTypes=KonqPopupMenu/Plugin
MimeType=inode/directory;
Actions=OrdenarExt;OrdenarFecha;OrdenarInicial;OrdenarUndo;
X-KDE-Submenu=Ordenar

[Desktop Action OrdenarExt]
Name=Por extensiones
Exec=/usr/bin/ordenar-contextual.sh "%f"
Icon=view-sort-ascending

[Desktop Action OrdenarFecha]
Name=Por fecha (año-mes)
Exec=/usr/bin/ordenar-contextual.sh --modo fecha "%f"
Icon=view-calendar

[Desktop Action OrdenarInicial]
Name=Por inicial
Exec=/usr/bin/ordenar-contextual.sh --modo inicial "%f"
Icon=insert-text

[Desktop Action OrdenarUndo]
Name=Deshacer última ordenación
Exec=/usr/bin/ordenar-contextual.sh --modo deshacer "%f"
Icon=edit-undo
EOF

cat > "${PKG_ROOT}/DEBIAN/postinst" <<'EOF'
#!/usr/bin/env bash
set -e
cat <<'MSG'
Para Thunar (XFCE), ejecuta una vez en tu sesión de usuario:
  ordenar-instalar-thunar
MSG
exit 0
EOF
chmod 0755 "${PKG_ROOT}/DEBIAN/postinst"

cat > "${PKG_ROOT}/DEBIAN/prerm" <<'EOF'
#!/usr/bin/env bash
set -e
cat <<'MSG'
Si usabas Thunar, elimina la acción personalizada con:
  ordenar-desinstalar-thunar
MSG
exit 0
EOF
chmod 0755 "${PKG_ROOT}/DEBIAN/prerm"

cp "${ROOT_DIR}/README.md" "${PKG_ROOT}/usr/share/doc/${PKG_NAME}/README.md"

if [[ -f "${DEBIAN_CHANGELOG_SOURCE}" ]]; then
  gzip -n -9 -c "${DEBIAN_CHANGELOG_SOURCE}" > "${PKG_ROOT}/usr/share/doc/${PKG_NAME}/changelog.Debian.gz"
else
  cat > "${PKG_ROOT}/usr/share/doc/${PKG_NAME}/changelog.Debian" <<EOF
${PKG_NAME} (${VERSION}) unstable; urgency=medium

  * Build sin changelog fuente en debian/changelog.

 -- ${MAINTAINER_NAME} <${MAINTAINER_EMAIL}>  $(date -R)
EOF
  gzip -n -9 "${PKG_ROOT}/usr/share/doc/${PKG_NAME}/changelog.Debian"
fi

mkdir -p "${DIST_DIR}"
dpkg-deb --build "${PKG_ROOT}" "${DIST_DIR}/${PKG_NAME}_${VERSION}_all.deb"

echo "Paquete generado: ${DIST_DIR}/${PKG_NAME}_${VERSION}_all.deb"

#!/usr/bin/env bash
set -euo pipefail

LOCAL_BIN="${HOME}/.local/bin"
APP_BIN="${LOCAL_BIN}/ordenar-por-extension"
CTX_BIN="${LOCAL_BIN}/ordenar-contextual.sh"
NAUTILUS_EXT_FILE="${HOME}/.local/share/nautilus-python/extensions/ordenar_por_extension.py"

remove_if_exists() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    rm -f "$path"
    echo "Eliminado: $path"
  fi
}

uninstall_thunar() {
  python3 - <<'PY'
from pathlib import Path
import xml.etree.ElementTree as ET

uca_path = Path.home() / ".config" / "Thunar" / "uca.xml"
if not uca_path.exists():
    print("No existe configuración de Thunar.")
    raise SystemExit(0)

try:
    tree = ET.parse(uca_path)
except ET.ParseError:
    print("No se pudo parsear uca.xml; omitiendo limpieza de Thunar.")
    raise SystemExit(0)

root = tree.getroot()
removed = False

for action in list(root.findall("action")):
    name = action.findtext("name", default="")
    command = action.findtext("command", default="")
    if name == "Ordenar por extensiones" or "ordenar-contextual.sh" in command:
        root.remove(action)
        removed = True

if removed:
    ET.indent(tree, space="  ")
    tree.write(uca_path, encoding="utf-8", xml_declaration=True)
    print(f"Acción eliminada de {uca_path}")
else:
    print("No se encontraron acciones de Thunar para eliminar.")
PY
}

main() {
  echo "Desinstalando Ordenar-archivos..."

  remove_if_exists "$APP_BIN"
  remove_if_exists "$CTX_BIN"
  remove_if_exists "$NAUTILUS_EXT_FILE"

  remove_if_exists "${HOME}/.local/share/nautilus/scripts/Ordenar"
  remove_if_exists "${HOME}/.local/share/nautilus/scripts/Ordenar por extensiones"
  remove_if_exists "${HOME}/.local/share/nautilus/scripts/Ordenar por fecha"
  remove_if_exists "${HOME}/.local/share/nautilus/scripts/Ordenar por inicial"
  remove_if_exists "${HOME}/.local/share/nautilus/scripts/Deshacer última ordenación"

  remove_if_exists "${HOME}/.local/share/nemo/scripts/Ordenar"
  remove_if_exists "${HOME}/.local/share/nemo/scripts/Ordenar por extensiones"
  remove_if_exists "${HOME}/.local/share/nemo/scripts/Ordenar por fecha"
  remove_if_exists "${HOME}/.local/share/nemo/scripts/Ordenar por inicial"
  remove_if_exists "${HOME}/.local/share/nemo/scripts/Deshacer última ordenación"

  remove_if_exists "${HOME}/.config/caja/scripts/Ordenar"
  remove_if_exists "${HOME}/.config/caja/scripts/Ordenar por extensiones"
  remove_if_exists "${HOME}/.config/caja/scripts/Ordenar por fecha"
  remove_if_exists "${HOME}/.config/caja/scripts/Ordenar por inicial"
  remove_if_exists "${HOME}/.config/caja/scripts/Deshacer última ordenación"
  remove_if_exists "${HOME}/.local/share/kio/servicemenus/ordenar-por-extension.desktop"

  uninstall_thunar

  echo "Desinstalación completada."
}

main "$@"

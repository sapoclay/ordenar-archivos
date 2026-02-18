#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BIN="${HOME}/.local/bin"
APP_BIN="${LOCAL_BIN}/ordenar-por-extension"
CTX_BIN="${LOCAL_BIN}/ordenar-contextual.sh"
NAUTILUS_EXT_DIR="${HOME}/.local/share/nautilus-python/extensions"
NAUTILUS_EXT_FILE="${NAUTILUS_EXT_DIR}/ordenar_por_extension.py"

install_core() {
  mkdir -p "$LOCAL_BIN"
  cp "$ROOT_DIR/bin/ordenar_por_extension.py" "$APP_BIN"
  cp "$ROOT_DIR/bin/ordenar_contextual.sh" "$CTX_BIN"
  chmod +x "$APP_BIN" "$CTX_BIN"
}

install_script_menu() {
  local target_dir="$1"
  local launcher_name="$2"
  local launcher_mode="$3"
  mkdir -p "$target_dir"
  local launcher="$target_dir/$launcher_name"

  cat > "$launcher" <<EOF
#!/usr/bin/env bash
exec "${CTX_BIN}" --modo ${launcher_mode} "\$@"
EOF
  chmod +x "$launcher"
}

install_script_menus() {
  local target_dir="$1"
  install_script_menu "$target_dir" "Ordenar por extensiones" "extension"
  install_script_menu "$target_dir" "Ordenar por fecha" "fecha"
  install_script_menu "$target_dir" "Ordenar por inicial" "inicial"
  install_script_menu "$target_dir" "Deshacer última ordenación" "deshacer"
}

install_nautilus() {
  install_script_menus "${HOME}/.local/share/nautilus/scripts"

  mkdir -p "${NAUTILUS_EXT_DIR}"
  cp "$ROOT_DIR/bin/nautilus_ordenar_extension.py" "${NAUTILUS_EXT_FILE}"
  chmod +x "${NAUTILUS_EXT_FILE}"
}

install_nemo() {
  install_script_menus "${HOME}/.local/share/nemo/scripts"
}

install_caja() {
  install_script_menus "${HOME}/.config/caja/scripts"
}

install_dolphin() {
  local dir="${HOME}/.local/share/kio/servicemenus"
  mkdir -p "$dir"

  cat > "${dir}/ordenar-por-extension.desktop" <<EOF
[Desktop Entry]
Type=Service
X-KDE-ServiceTypes=KonqPopupMenu/Plugin
MimeType=inode/directory;
Actions=OrdenarExt;OrdenarFecha;OrdenarInicial;OrdenarUndo;
X-KDE-Submenu=Ordenar

[Desktop Action OrdenarExt]
Name=Por extensiones
Exec=${CTX_BIN} "%f"
Icon=view-sort-ascending

[Desktop Action OrdenarFecha]
Name=Por fecha (año-mes)
Exec=${CTX_BIN} --modo fecha "%f"
Icon=view-calendar

[Desktop Action OrdenarInicial]
Name=Por inicial
Exec=${CTX_BIN} --modo inicial "%f"
Icon=insert-text

[Desktop Action OrdenarUndo]
Name=Deshacer última ordenación
Exec=${CTX_BIN} --modo deshacer "%f"
Icon=edit-undo
EOF
}

install_thunar() {
  python3 - <<'PY'
from pathlib import Path
import xml.etree.ElementTree as ET

uca_path = Path.home() / ".config" / "Thunar" / "uca.xml"
uca_path.parent.mkdir(parents=True, exist_ok=True)

if uca_path.exists() and uca_path.read_text(encoding="utf-8", errors="ignore").strip():
    tree = ET.parse(uca_path)
    root = tree.getroot()
else:
    root = ET.Element("actions")
    tree = ET.ElementTree(root)

base_command = str(Path.home() / ".local" / "bin" / "ordenar-contextual.sh")
acciones = [
  {
    "name": "Ordenar por extensiones",
    "command": f"{base_command} --modo extension %f",
    "description": "Ordena archivos de la carpeta por extensión",
    "icon": "view-sort-ascending",
    "id": "173985000001",
  },
  {
    "name": "Ordenar por fecha",
    "command": f"{base_command} --modo fecha %f",
    "description": "Ordena archivos por fecha de modificación (año-mes)",
    "icon": "view-calendar",
    "id": "173985000002",
  },
  {
    "name": "Ordenar por inicial",
    "command": f"{base_command} --modo inicial %f",
    "description": "Ordena archivos por la inicial del nombre",
    "icon": "insert-text",
    "id": "173985000003",
  },
  {
    "name": "Deshacer última ordenación",
    "command": f"{base_command} --modo deshacer %f",
    "description": "Revierte la última ordenación aplicada en la carpeta",
    "icon": "edit-undo",
    "id": "173985000004",
  },
]

for meta in acciones:
  for action in root.findall("action"):
    name = action.findtext("name", default="")
    command = action.findtext("command", default="")
    if name == meta["name"] or command == meta["command"]:
      break
  else:
    action = ET.SubElement(root, "action")
    ET.SubElement(action, "icon").text = meta["icon"]
    ET.SubElement(action, "name").text = meta["name"]
    ET.SubElement(action, "submenu").text = "Ordenar"
    ET.SubElement(action, "unique-id").text = meta["id"]
    ET.SubElement(action, "command").text = meta["command"]
    ET.SubElement(action, "description").text = meta["description"]
    ET.SubElement(action, "patterns").text = "*"
    ET.SubElement(action, "directories").text = ""
    ET.SubElement(action, "audio-files").text = ""
    ET.SubElement(action, "image-files").text = ""
    ET.SubElement(action, "other-files").text = ""
    ET.SubElement(action, "text-files").text = ""
    ET.SubElement(action, "video-files").text = ""

ET.indent(tree, space="  ")
tree.write(uca_path, encoding="utf-8", xml_declaration=True)
print(f"Thunar action instalada en {uca_path}")
PY
}

main() {
  echo "Instalando Ordenar-archivos..."
  install_core

  install_nautilus
  install_nemo
  install_caja
  install_thunar
  install_dolphin

  echo
  echo "Instalación completada."
  echo "Si no aparece la opción en el menú contextual, reinicia el gestor de archivos."
  echo "- Nautilus: nautilus -q"
  echo "- Nemo: nemo -q"
  echo "- Caja: caja -q"
  echo "- Thunar: cerrar/reabrir Thunar"
  echo "- Dolphin: kquitapp5 dolphin && dolphin &"
}

main "$@"

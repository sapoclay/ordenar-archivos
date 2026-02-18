#!/usr/bin/env python3
from pathlib import Path
import xml.etree.ElementTree as ET


def main() -> int:
    uca_path = Path.home() / ".config" / "Thunar" / "uca.xml"
    if not uca_path.exists():
        print("No existe configuración de Thunar.")
        return 0

    try:
        tree = ET.parse(uca_path)
    except ET.ParseError:
        print("No se pudo parsear uca.xml; no se modifica.")
        return 0

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
        print("No se encontraron acciones para eliminar.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

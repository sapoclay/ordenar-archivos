#!/usr/bin/env python3
from pathlib import Path
import xml.etree.ElementTree as ET


def main() -> int:
    uca_path = Path.home() / ".config" / "Thunar" / "uca.xml"
    uca_path.parent.mkdir(parents=True, exist_ok=True)

    if uca_path.exists() and uca_path.read_text(encoding="utf-8", errors="ignore").strip():
        tree = ET.parse(uca_path)
        root = tree.getroot()
    else:
        root = ET.Element("actions")
        tree = ET.ElementTree(root)

    acciones = [
        {
            "name": "Ordenar por extensiones",
            "command": "ordenar-contextual.sh --modo extension %f",
            "description": "Ordena archivos de la carpeta por extensión",
            "icon": "view-sort-ascending",
            "id": "173985000001",
        },
        {
            "name": "Ordenar por fecha",
            "command": "ordenar-contextual.sh --modo fecha %f",
            "description": "Ordena archivos por fecha de modificación (año-mes)",
            "icon": "view-calendar",
            "id": "173985000002",
        },
        {
            "name": "Ordenar por inicial",
            "command": "ordenar-contextual.sh --modo inicial %f",
            "description": "Ordena archivos por la inicial del nombre",
            "icon": "insert-text",
            "id": "173985000003",
        },
        {
            "name": "Deshacer última ordenación",
            "command": "ordenar-contextual.sh --modo deshacer %f",
            "description": "Revierte la última ordenación aplicada en la carpeta",
            "icon": "edit-undo",
            "id": "173985000004",
        },
    ]

    added = 0
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
            added += 1

    if added == 0:
        print("Las acciones de Thunar ya existen.")
        return 0

    ET.indent(tree, space="  ")
    tree.write(uca_path, encoding="utf-8", xml_declaration=True)
    print(f"Acciones de Thunar instaladas/actualizadas en {uca_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

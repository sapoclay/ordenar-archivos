#!/usr/bin/env python3
import subprocess
from urllib.parse import unquote

from gi.repository import GObject, Nautilus


def _uri_to_path(uri: str) -> str:
    if uri.startswith("file://"):
        return unquote(uri[7:])
    return unquote(uri)


class OrdenarNautilusExtension(GObject.GObject, Nautilus.MenuProvider):
    def _run_sort(self, _menu, target_dir: str, modo: str) -> None:
        subprocess.Popen(["/usr/bin/ordenar-contextual.sh", "--modo", modo, target_dir])

    def _sub_item(self, target_dir: str, modo: str, label: str, tip: str, icon: str):
        item = Nautilus.MenuItem(
            name=f"OrdenarNautilusExtension::{modo}",
            label=label,
            tip=tip,
            icon=icon,
        )
        item.connect("activate", self._run_sort, target_dir, modo)
        return item

    def _menu_item(self, target_dir: str):
        menu_root = Nautilus.MenuItem(
            name="OrdenarNautilusExtension::Ordenar",
            label="Ordenar",
            tip="Ordenar archivos por distintos criterios",
            icon="view-sort-ascending",
        )

        submenu = Nautilus.Menu()
        submenu.append_item(
            self._sub_item(
                target_dir,
                "extension",
                "Por extensiones",
                "Ordena archivos por extensión",
                "view-sort-ascending",
            )
        )
        submenu.append_item(
            self._sub_item(
                target_dir,
                "fecha",
                "Por fecha (año-mes)",
                "Ordena archivos por fecha de modificación",
                "view-calendar",
            )
        )
        submenu.append_item(
            self._sub_item(
                target_dir,
                "inicial",
                "Por inicial",
                "Ordena archivos por la inicial del nombre",
                "insert-text",
            )
        )
        submenu.append_item(
            self._sub_item(
                target_dir,
                "deshacer",
                "Deshacer última ordenación",
                "Revierte la última ordenación aplicada en esta carpeta",
                "edit-undo",
            )
        )
        menu_root.set_submenu(submenu)
        return menu_root

    def get_background_items(self, current_folder):
        try:
            folder_uri = current_folder.get_uri()
            target_dir = _uri_to_path(folder_uri)
        except Exception:
            return

        return (self._menu_item(target_dir),)

    def get_file_items(self, files):
        if not files:
            return

        first = files[0]
        try:
            if first.is_directory():
                target_uri = first.get_uri()
            else:
                parent = first.get_parent_info()
                if parent is None:
                    return
                target_uri = parent.get_uri()
            target_dir = _uri_to_path(target_uri)
        except Exception:
            return

        return (self._menu_item(target_dir),)

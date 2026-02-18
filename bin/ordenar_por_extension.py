#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
import sys
from datetime import datetime
from pathlib import Path

UNDO_FILENAME = ".ordenar_archivos_undo.json"


def carpeta_destino_por_extension(archivo: Path) -> str:
    if archivo.name.startswith(".") and archivo.suffix == "":
        return "sin_extension"

    extension = archivo.suffix.lower().lstrip(".")
    if not extension:
        return "sin_extension"
    return extension


def carpeta_destino_por_fecha(archivo: Path) -> str:
    try:
        marca_tiempo = archivo.stat().st_mtime
    except OSError:
        return "fecha_desconocida"

    fecha = datetime.fromtimestamp(marca_tiempo)
    return f"fecha_{fecha.strftime('%Y-%m')}"


def carpeta_destino_por_inicial(archivo: Path) -> str:
    nombre_base = archivo.stem or archivo.name
    nombre_limpio = nombre_base.lstrip(".").strip()

    if not nombre_limpio:
        return "inicial_otros"

    inicial = nombre_limpio[0].lower()
    if inicial.isalpha():
        return f"inicial_{inicial}"
    if inicial.isdigit():
        return "inicial_0-9"
    return "inicial_otros"


def resolver_carpeta_destino(archivo: Path, modo: str) -> str:
    if modo == "fecha":
        return carpeta_destino_por_fecha(archivo)
    if modo == "inicial":
        return carpeta_destino_por_inicial(archivo)
    return carpeta_destino_por_extension(archivo)


def resolver_colision(destino: Path) -> Path:
    if not destino.exists():
        return destino

    base = destino.stem
    sufijo = destino.suffix
    parent = destino.parent
    indice = 1

    while True:
        candidato = parent / f"{base}_{indice}{sufijo}"
        if not candidato.exists():
            return candidato
        indice += 1


def guardar_estado_undo(carpeta: Path, modo: str, operaciones: list[dict[str, str]]) -> None:
    payload = {
        "version": 1,
        "modo": modo,
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        "operaciones": operaciones,
    }
    estado_path = carpeta / UNDO_FILENAME
    estado_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def cargar_estado_undo(carpeta: Path) -> dict:
    estado_path = carpeta / UNDO_FILENAME
    if not estado_path.exists():
        raise ValueError("No hay una operación para deshacer en esta carpeta.")

    try:
        return json.loads(estado_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"Estado de deshacer inválido: {exc}") from exc


def deshacer_ordenacion(carpeta: Path, dry_run: bool = False) -> tuple[int, int, str]:
    if not carpeta.exists() or not carpeta.is_dir():
        raise ValueError(f"Ruta no válida: {carpeta}")

    estado = cargar_estado_undo(carpeta)
    operaciones = estado.get("operaciones", [])
    if not isinstance(operaciones, list) or not operaciones:
        raise ValueError("No hay movimientos registrados para deshacer.")

    restaurados = 0
    omitidos = 0

    for op in reversed(operaciones):
        origen_rel = op.get("destino")
        destino_rel = op.get("origen")
        if not origen_rel or not destino_rel:
            omitidos += 1
            continue

        origen = carpeta / origen_rel
        destino = carpeta / destino_rel

        if not origen.exists() or not origen.is_file():
            omitidos += 1
            continue

        destino.parent.mkdir(parents=True, exist_ok=True)
        destino_final = resolver_colision(destino)

        if dry_run:
            print(f"[DRY-RUN] {origen_rel} -> {destino_final.relative_to(carpeta)}")
            restaurados += 1
            continue

        shutil.move(str(origen), str(destino_final))
        restaurados += 1

    if not dry_run:
        directorios = set()
        for op in operaciones:
            destino_rel = op.get("destino")
            if not destino_rel:
                continue
            parent = (carpeta / destino_rel).parent
            while parent != carpeta and parent not in directorios:
                directorios.add(parent)
                parent = parent.parent

        for directory in sorted(directorios, key=lambda d: len(d.parts), reverse=True):
            try:
                directory.rmdir()
            except OSError:
                pass

        (carpeta / UNDO_FILENAME).unlink(missing_ok=True)

    modo_original = estado.get("modo", "desconocido")
    return restaurados, omitidos, str(modo_original)


def ordenar_carpeta(carpeta: Path, modo: str, dry_run: bool = False) -> tuple[int, int]:
    if not carpeta.exists() or not carpeta.is_dir():
        raise ValueError(f"Ruta no válida: {carpeta}")

    movidos = 0
    omitidos = 0
    operaciones: list[dict[str, str]] = []

    for elemento in carpeta.iterdir():
        if elemento.name == UNDO_FILENAME:
            omitidos += 1
            continue

        if not elemento.is_file():
            omitidos += 1
            continue

        nombre_carpeta = resolver_carpeta_destino(elemento, modo)
        destino_carpeta = carpeta / nombre_carpeta
        destino_carpeta.mkdir(exist_ok=True)

        destino_archivo = resolver_colision(destino_carpeta / elemento.name)

        if dry_run:
            print(f"[DRY-RUN] {elemento.name} -> {destino_carpeta.name}/{destino_archivo.name}")
            movidos += 1
            continue

        shutil.move(str(elemento), str(destino_archivo))
        operaciones.append(
            {
                "origen": elemento.name,
                "destino": str(destino_archivo.relative_to(carpeta)),
            }
        )
        movidos += 1

    if not dry_run and operaciones:
        guardar_estado_undo(carpeta, modo, operaciones)

    return movidos, omitidos


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Ordena los archivos de una carpeta por criterio."
    )
    parser.add_argument(
        "carpeta",
        nargs="?",
        default=".",
        help="Carpeta objetivo (por defecto: carpeta actual).",
    )
    parser.add_argument(
        "--modo",
        choices=["extension", "fecha", "inicial", "deshacer"],
        default="extension",
        help="Criterio: extension (default), fecha (año-mes), inicial, deshacer (revierte última ordenación).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Muestra qué se movería, sin hacer cambios.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    carpeta = Path(args.carpeta).expanduser().resolve()
    movidos = 0
    restaurados = 0
    modo_original = "desconocido"

    try:
        if args.modo == "deshacer":
            restaurados, omitidos, modo_original = deshacer_ordenacion(carpeta, dry_run=args.dry_run)
        else:
            movidos, omitidos = ordenar_carpeta(carpeta, modo=args.modo, dry_run=args.dry_run)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 2
    except PermissionError as exc:
        print(f"Sin permisos suficientes: {exc}", file=sys.stderr)
        return 3
    except Exception as exc:
        print(f"Error inesperado: {exc}", file=sys.stderr)
        return 1

    print(f"Carpeta: {carpeta}")
    print(f"Modo: {args.modo}")
    if args.modo == "deshacer":
        print(f"Modo original restaurado: {modo_original}")
        print(f"Archivos restaurados: {restaurados}")
    else:
        print(f"Archivos movidos: {movidos}")
    print(f"Elementos omitidos (directorios/enlaces): {omitidos}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

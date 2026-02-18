#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${APP_CMD:-}" ]]; then
  APP_CMD_RESUELTO="$APP_CMD"
elif command -v ordenar-por-extension >/dev/null 2>&1; then
  APP_CMD_RESUELTO="$(command -v ordenar-por-extension)"
else
  APP_CMD_RESUELTO="${HOME}/.local/bin/ordenar-por-extension"
fi

uri_to_path() {
  local uri="$1"
  uri="${uri#file://}"
  printf '%b' "${uri//%/\\x}"
}

modo_ordenar="${ORDENAR_MODO:-extension}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --modo)
      if [[ $# -lt 2 ]]; then
        echo "Falta valor para --modo" >&2
        exit 2
      fi
      modo_ordenar="$2"
      shift 2
      ;;
    --modo=*)
      modo_ordenar="${1#*=}"
      shift
      ;;
    *)
      break
      ;;
  esac
done

case "$modo_ordenar" in
  extension|fecha|inicial|deshacer) ;;
  *)
    echo "Modo no válido: $modo_ordenar (usa: extension, fecha, inicial, deshacer)" >&2
    exit 2
    ;;
esac

resolver_directorio_objetivo() {
  if [[ $# -gt 0 ]]; then
    if [[ -d "$1" ]]; then
      printf '%s\n' "$1"
      return 0
    fi
    if [[ -f "$1" ]]; then
      dirname "$1"
      return 0
    fi
  fi

  local current_uri="${NAUTILUS_SCRIPT_CURRENT_URI:-${NEMO_SCRIPT_CURRENT_URI:-${CAJA_SCRIPT_CURRENT_URI:-}}}"
  if [[ -n "$current_uri" ]]; then
    uri_to_path "$current_uri"
    return 0
  fi

  printf '%s\n' "$PWD"
}

dir_objetivo="$(resolver_directorio_objetivo "$@")"

if [[ ! -x "$APP_CMD_RESUELTO" ]]; then
  echo "No se encontró el comando $APP_CMD_RESUELTO" >&2
  exit 1
fi

if "$APP_CMD_RESUELTO" --modo "$modo_ordenar" "$dir_objetivo"; then
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Ordenar archivos" "Completado ($modo_ordenar) en: $dir_objetivo"
  fi
else
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Ordenar archivos" "Error al ordenar ($modo_ordenar) en: $dir_objetivo"
  fi
  exit 1
fi

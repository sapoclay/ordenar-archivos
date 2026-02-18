# Ordenar archivos por criterio (Ubuntu)

![ordenar-archivos](https://github.com/user-attachments/assets/a5baf71b-7ede-47a6-9c0e-e665c5491d7b)

Esta aplicación añade opciones de **Ordenar** en el menú contextual (clic derecho) para ordenar los archivos de la carpeta por:

- **Extensión**
- **Fecha de modificación** (agrupado por año-mes)
- **Inicial del nombre**

También incluye la opción **Deshacer última ordenación** para restaurar los archivos a su estado previo.

## Gestores de archivos soportados

- Nautilus (GNOME Files): **Ordenar > Por extensiones / Por fecha / Por inicial / Deshacer última ordenación**
- Nemo (Linux Mint): menú contextual en **Scripts > Ordenar por extensiones / fecha / inicial / Deshacer última ordenación**
- Caja (MATE): menú contextual en **Scripts > Ordenar por extensiones / fecha / inicial / Deshacer última ordenación**
- Thunar (XFCE): acciones personalizadas en **Ordenar > Por extensiones / fecha / inicial / Deshacer última ordenación**
- Dolphin (KDE): submenú **Ordenar > Por extensiones / fecha / inicial / Deshacer última ordenación**

> Nota: cada gestor implementa el menú contextual de forma diferente; por eso se instala un adaptador por gestor.

### Nota específica para GNOME (Nautilus) ... que es el que yo utilizo

En GNOME moderno, el menú **Scripts** puede no aparecer dentro de carpetas en algunas configuraciones.
Para asegurar que aparezca en clic derecho dentro de carpetas, también se instala una extensión de Nautilus
(`python3-nautilus`) con submenú **Ordenar** y los 4 modos (incluye **Deshacer última ordenación**).

Si no tienes `python3-nautilus`:

```bash
sudo apt install python3-nautilus
```

Si instalas el paquete `.deb` con `apt`, `python3-nautilus` se instalará automáticamente
como dependencia.

## Qué hace exactamente

- Recorre los archivos de la carpeta seleccionada.
- Crea subcarpetas según el criterio elegido.
- Mueve cada archivo a su subcarpeta correspondiente.
- Modo `extension`: `jpg`, `pdf`, `txt`, etc. (sin extensión a `sin_extension`).
- Modo `fecha`: `fecha_YYYY-MM` según fecha de modificación.
- Modo `inicial`: `inicial_a`, `inicial_b`, `inicial_0-9`, `inicial_otros`.
- Si hay colisión de nombre, crea sufijos (`archivo_1.txt`, `archivo_2.txt`, ...).
- Se guarda un estado de la última ordenación en `.ordenar_archivos_undo.json` para poder ejecutar `deshacer` sobre esa carpeta.
- `deshacer` revierte **solo la última ordenación registrada** en esa carpeta.
- Al ejecutar una nueva ordenación, el estado anterior se reemplaza por el nuevo.

## Instalación

Desde la raíz del proyecto:

```bash
chmod +x install.sh uninstall.sh
./install.sh
```

## Empaquetado `.deb`

Generar el paquete:

```bash
chmod +x packaging/build_deb.sh
./packaging/build_deb.sh 1.0.1
```

Con metadatos personalizados (mantenedor y descripción):

```bash
MAINTAINER_NAME="Tu Nombre" \
MAINTAINER_EMAIL="tu@email.com" \
PKG_SHORT_DESC="Ordenador contextual de archivos por criterio" \
PKG_LONG_DESC="Ordena y deshace organización por extensión, fecha o inicial desde el menú contextual." \
./packaging/build_deb.sh 1.0.1
```

Actualizar changelog Debian para una nueva versión:

```bash
chmod +x packaging/update_changelog.sh
./packaging/update_changelog.sh 1.0.2 "Mejoras en integración y empaquetado."
```

Hacer release completa (changelog + build) en un solo paso:

```bash
chmod +x packaging/release.sh
./packaging/release.sh 1.0.3 "Ajustes y mejoras de release."
```

Si no pasas mensaje en `release.sh`, el changelog se completa automáticamente con commits recientes:

```bash
./packaging/release.sh 1.0.4
```

Validaciones del release:

- Si la versión ya existe en `debian/changelog`, falla.
- Si ya existe `dist/ordenar-archivos_<version>_all.deb`, falla.
- Puedes forzar (bajo tu responsabilidad):

```bash
FORCE_RELEASE=1 ./packaging/release.sh 1.0.3 "Rebuild forzado"
```

El paquete incluirá automáticamente:

```bash
usr/share/doc/ordenar-archivos/changelog.Debian.gz
```

Se creará en:

```bash
dist/ordenar-archivos_1.0.1_all.deb
```

Instalar el paquete:

```bash
sudo apt install ./dist/ordenar-archivos_1.0.1_all.deb
```

Para Thunar (XFCE), tras instalar el `.deb`, ejecuta en tu usuario:

```bash
ordenar-instalar-thunar
```

## Reiniciar el gestor de archivos

Si la opción no aparece inmediatamente:

```bash
nautilus -q   # Nautilus
nemo -q       # Nemo
caja -q       # Caja
# Thunar: cerrar y abrir de nuevo
kquitapp5 dolphin && dolphin &   # Dolphin
```

## Uso manual (sin menú contextual)

```bash
~/.local/bin/ordenar-por-extension --modo extension /ruta/a/la/carpeta

# Otros modos
~/.local/bin/ordenar-por-extension --modo fecha /ruta/a/la/carpeta
~/.local/bin/ordenar-por-extension --modo inicial /ruta/a/la/carpeta
~/.local/bin/ordenar-por-extension --modo deshacer /ruta/a/la/carpeta
```

Simulación sin cambios:

```bash
~/.local/bin/ordenar-por-extension --modo fecha /ruta/a/la/carpeta --dry-run
~/.local/bin/ordenar-por-extension --modo deshacer /ruta/a/la/carpeta --dry-run
```

## Limitaciones conocidas

- `deshacer` solo revierte la **última** ordenación registrada por carpeta.
- Si ejecutas una nueva ordenación en la misma carpeta, reemplaza el estado anterior de deshacer.
- `deshacer` depende del archivo `.ordenar_archivos_undo.json`; si se elimina o modifica manualmente, no se podrá restaurar el estado previo de forma fiable.
- Si durante la ordenación/deshacer se mueven o renombran archivos manualmente, la reversión puede ser parcial.
- No se deshacen cambios hechos fuera de esta herramienta.
- En algunos entornos GNOME, el menú **Scripts** puede no mostrarse dentro de carpetas; para ese caso se usa la extensión de Nautilus (`python3-nautilus`).

## Desinstalación

```bash
./uninstall.sh
```

Si instalaste con `.deb`:

```bash
sudo apt remove ordenar-archivos
```

Y para limpiar acción en Thunar:

```bash
ordenar-desinstalar-thunar
```

## Archivos principales

- `bin/ordenar_por_extension.py`: lógica principal de ordenado.
- `bin/ordenar_contextual.sh`: launcher invocado desde menú contextual.
- `install.sh`: instala comando y adaptadores para gestores.
- `uninstall.sh`: revierte la instalación.

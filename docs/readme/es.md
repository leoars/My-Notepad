# My Notepad

[Português (Brasil)](../../README.md) · [English](en.md) · **Español** · [Français](fr.md) · [Deutsch](de.md) · [Italiano](it.md) · [日本語](ja.md) · [한국어](ko.md)

**Suite My:** [My Explorer](https://github.com/leoars/my-explorer/blob/main/README.es.md) · **My Notepad** · [My Paint](https://github.com/leoars/my-paint/blob/main/docs/readme/es.md)

Un editor de texto sencillo para macOS. Abre un .txt, escribe y guarda con los atajos que tus manos ya conocen.

## Descargar para macOS

- **[Descargar para Apple Silicon (serie M)](https://github.com/leoars/My-Notepad/releases/download/1.0.2/My-Notepad-1.0.2-arm64.pkg)**
- **[Descargar para Intel](https://github.com/leoars/My-Notepad/releases/download/1.0.2/My-Notepad-1.0.2-x86_64.pkg)**

Requiere macOS 12 o posterior. [Ver la última versión](https://github.com/leoars/My-Notepad/releases/latest)

![Ventana del editor con un cuaderno de campo, la palabra «puente» seleccionada y la posición del cursor al pie.](../screenshots/es-editor.png)

## Por qué existe My Notepad

My Notepad nació de echar en falta un editor de texto que vaya directo al grano. Para apuntar una dirección o corregir una línea de un archivo antiguo, bastan una ventana, cinco menús y el cursor. El proyecto ofrece esa forma de trabajar en Swift y AppKit. Cada ventana edita un documento, y la fuente elegida se aplica a la visualización. El archivo sigue siendo texto plano.

## Funciones

### Archivo

- **Nuevo**, **Abrir…**, **Guardar** y **Guardar como…**. Al cerrar, abrir o crear un documento con cambios pendientes, el editor pregunta si quieres guardarlos.
- Abre archivos de texto desde el Finder, incluso con la aplicación cerrada, y la primera vez que lo abres se ofrece como editor predeterminado de los archivos .txt.
- **Salir** cierra la ventana y, con ella, la aplicación.

### Edición

- **Deshacer** y **Rehacer**, **Cortar**, **Copiar**, **Pegar**, **Eliminar** y **Seleccionar todo**.
- **Hora y fecha** inserta la hora y la fecha en la posición del cursor.
- Texto plano de verdad: sin corrector ortográfico, sin sustituciones automáticas y sin formato oculto.

### Buscar y reemplazar

- **Buscar…** con dirección (arriba o abajo) y la opción de distinguir mayúsculas y minúsculas. **Buscar siguiente** repite la búsqueda.
- **Reemplazar…** con **Reemplazar** y **Reemplazar todo**. El panel se abre con el texto seleccionado ya escrito y sigue abierto mientras trabajas.
- **Ir a…** salta a una línea por su número (con el ajuste de línea desactivado).

![Panel Reemplazar preparado para cambiar «puente» por «pasarela».](../screenshots/es-replace.png)

### Formato y vista

- **Ajuste de línea**, activado o desactivado.
- **Fuente…**: familia, estilo (normal, cursiva, negrita, negrita cursiva) y tamaño. La elección se aplica a la visualización y se recuerda.
- Tamaño de la fuente desde el teclado o manteniendo pulsada **Ctrl** y girando la rueda del ratón.
- **Barra de estado** con la línea y la columna del cursor.

### Codificaciones y finales de línea

- Abre y guarda en ANSI (CP-1252), UTF-8, UTF-16 LE y UTF-16 BE, con detección automática o elección manual al abrir y al guardar.
- Reconoce los finales de línea CRLF, LF y CR, y guarda el archivo con el mismo final de línea.
- Si un carácter no cabe en la codificación elegida, el editor ofrece guardar en UTF-8.

### Imprimir

- **Configurar página…**: encabezado, pie de página, los cuatro márgenes, papel y orientación.
- Códigos de encabezado y pie de página: `&f` (nombre del archivo), `&p` (página), `&d` (fecha), `&t` (hora), `&l`, `&c` y `&r` (alineación).
- **Imprimir…** usa la fuente del editor.

### Un diario en .txt

Escribe `.LOG` en la primera línea de un archivo, guárdalo y vuelve a abrirlo. El editor añade la hora y la fecha al final para que escribas la siguiente entrada. Guarda los cambios para conservarla.

### Interfaz e idiomas

- Menús dentro de la ventana (Archivo, Editar, Formato, Ver, Ayuda), además de la barra de menús de macOS. **Option** con la letra del menú lo abre desde el teclado.
- La posición y el tamaño de la ventana se recuerdan.
- Disponible en portugués, inglés, español, francés, alemán, italiano, japonés y coreano.

### Atajos de teclado

Los atajos con `Ctrl` funcionan como ya los conoces; los de menú también aceptan `Cmd`.

| Teclas | Acción |
| --- | --- |
| `Ctrl+N` · `Ctrl+O` · `Ctrl+S` | Nuevo, abrir y guardar |
| `Ctrl+Shift+S` | Guardar como |
| `Ctrl+P` | Imprimir |
| `Ctrl+Z` · `Ctrl+Y` | Deshacer y rehacer |
| `Ctrl+X` · `Ctrl+C` · `Ctrl+V` · `Ctrl+A` | Cortar, copiar, pegar y seleccionar todo |
| `Ctrl+Insert` · `Shift+Insert` · `Shift+Delete` | Copiar, pegar y cortar |
| `Ctrl+F` · `F3` | Buscar y pasar a la siguiente coincidencia |
| `Ctrl+H` | Abrir Reemplazar |
| `Ctrl+G` | Ir a una línea |
| `F5` | Insertar la hora y la fecha |
| `Ctrl+←` / `→` | Mover el cursor por palabras |
| `Ctrl+Shift+←` / `→` | Ampliar o reducir la selección por palabras |
| `Ctrl+Backspace` · `Ctrl+Delete` | Borrar la palabra anterior o la siguiente |
| `Home` · `End` · `Ctrl+Home` · `Ctrl+End` | Inicio y fin de la línea o del documento |
| `Ctrl++` / `Ctrl+-` | Aumentar o reducir el tamaño de la fuente |
| `F1` | Ayuda |

## Parte de la suite My

My Notepad forma parte de la suite My: tres aplicaciones para macOS sencillas y directas, con los menús y los atajos de siempre.

- **My Notepad** (este repositorio): editor de texto sencillo.
- **[My Explorer](https://github.com/leoars/my-explorer/blob/main/README.es.md)**: gestor de archivos con árbol de carpetas, pestañas y barra de comandos. Con My Notepad instalado, el doble clic en un archivo .txt en My Explorer abre el texto aquí, y el menú contextual incorpora **Editar con My Notepad**.
- **[My Paint](https://github.com/leoars/my-paint/blob/main/docs/readme/es.md)**: editor de imágenes sencillo.

## Compilar e instalar en el Mac

Los instaladores son para macOS 12 o posterior, tanto en Apple Silicon como en Intel. Para compilar, necesitas las herramientas de desarrollo de Apple con el compilador Swift y Python 3. Desde la raíz del proyecto, ejecuta:

```sh
./build.sh
open "My Notepad.app"
```

Para ejecutar las pruebas automáticas:

```sh
./test.sh
```

Para generar ambos instaladores, ejecuta el siguiente comando. En `dist/`, elige el paquete `arm64` para Apple Silicon o `x86_64` para Intel. Abre el `.pkg` para instalar la aplicación en `/Applications`.

```sh
./package.sh
```

## Cómo contribuir

El [editor, los menús y la gestión de archivos](../../Sources) están escritos en Swift. Las [traducciones](../../Resources) se organizan en carpetas `.lproj` por idioma. Si detectas un problema con el teclado o los caracteres, indica la versión de macOS, la distribución del teclado o la codificación y un ejemplo que permita reproducirlo.

## Licencia

El código y la documentación originales se distribuyen bajo la [licencia Apache 2.0](../../LICENSE).

# qs-docs Aplicación: Documentación Técnica

## Resumen

La aplicación `qs-docs` es un visor de documentación técnica construido con QuickShell (Qt/QML) para mostrar y buscar documentos Markdown del directorio `~/ddubsos/docs/`. Ofrece una interfaz unificada para navegar documentación por categorías con búsqueda en tiempo real y soporte multilenguaje, diseñada específicamente para documentación técnica y notas de proyecto.

## Arquitectura

### Componentes principales

```
qs-docs/
├── modules/home/scripts/
│   ├── qs-docs.nix          # Script lanzador principal
│   └── docs-parser.nix      # Parser de archivos Markdown
└── modules/home/hyprland/
    └── windowrules.nix      # Reglas de ventana
```

### Pila tecnológica
- Shell: Bash con `set -euo pipefail`
- Parser: Bash + find/grep para procesar Markdown y generar JSON
- UI: Qt 6.x/QML con QuickShell
- Build: Nix (flake)
- WM: Hyprland con reglas personalizadas
- Formato de contenido: Archivos Markdown con soporte multilenguaje

## Estructura de archivos y código

### 1. Lanzador principal (`qs-docs.nix`)

Propósito: Analiza argumentos, descubre archivos de documentación y genera la interfaz QML.

CLI:
```bash
qs-docs [options]
  -c CATEGORY   (AI|ddubsos) (por defecto: AI)
  -l LANGUAGE   (en|es) (por defecto: en)
  -h            Ayuda
  --shell-only  Solo generar JSON (sin QML)

Variables de entorno:
  QS_PERF=1, QS_AUTO_QUIT=1, QS_SHELL_ONLY=1,
  DOCS_CATEGORY, DOCS_LANGUAGE
```

Validación de categoría (dinámica, incluye "root") y de idioma (en|es).

Pipeline de datos:
1) `mktemp -d`
2) JSON de ficheros (categoría/idioma) con docs-parser
3) JSON de categorías
4) Pre-generación para todas las categorías/idiomas
5) Generar QML y lanzar QuickShell

### 2. Parser de documentación (`docs-parser.nix`)

Entrada:
```bash
docs-parser MODE [CATEGORY] [LANGUAGE]
MODE: files|content|categories
```

- files: lista de archivos .md en raíz o subdirectorio de categoría, extrae título (primera cabecera H1), idioma (sufijo .es.md) y nombre limpio.
- content: igual que files pero añade el contenido (JSON-escaped) para consumo programático.
- categories: detecta categorías a partir del árbol de directorios (incluye "root" si hay .md en la raíz).

Funciones auxiliares: limpieza de nombre, detección de idioma, extracción de título.

### 3. Interfaz QML

Propiedades:
- Estado: `selectedCategory`, `selectedLanguage`, `selectedFile`, `fileContent`, `displayedContent`, `searchQuery`
- Búsqueda: `searchCount`, `currentMatchIndex`, `matchPositions`
- Datos: `docsFiles`, `availableCategories`, `filesModel`

Funciones clave:
- `loadDocsFiles()` carga JSON pre-generado por categoría/idioma
- `loadFileContent(filename)` lee archivo via `file://`
- `updateSearch()` y `rebuildDisplayedContent()` realizan y resaltan coincidencias
- Cambios de categoría/idioma recargan la lista

### 4. Gestión de ventanas (Hyprland)

Reglas destacadas:
```nix
"float, class:^(org\\.qt-project\\.qml)$, title:^(Documentation Viewer)$"
"center, class:^(org\\.qt-project\\.qml)$, title:^(Documentation Viewer)$"
"noborder|noshadow|rounding 12|opacity 0.95 0.95 ..."
```

## Flujos de datos
- Inicialización: Comando → argumentos → validaciones → JSON → QML → QuickShell
- Generación: find → metadatos/título/idioma → JSON
- UI: onCompleted → XHR local (file://) → JSON.parse → modelo QML
- Contenido: selección → XHR → búsqueda → HTML resaltado

## Estructuras JSON
- Objeto de archivo: `filename`, `clean_name`, `title`, `category`, `language`, `path`
- Categorías: array de strings (`root`, `AI`, `ddubsos`)

## Sistema de categorías

### Categorías disponibles
Basado en la estructura de archivos en `~/ddubsos/docs/`:

- `root` - Archivos en el directorio raíz de docs
- `AI` - Documentación de herramientas de Inteligencia Artificial
- `ddubsos` - Documentación y guías del sistema ddubsos

### Convenciones de nombres
- Inglés: `Tema-nombre-descripcion.md` (ej: `Warp-terminal-integration.md`)
- Español: `Tema-nombre-descripcion.es.md` (ej: `Warp-terminal-integration.es.md`)

## Errores y robustez
- Bash: `set -euo pipefail`, mensajes claros en validaciones
- QML: try/catch al parsear JSON, limpieza de modelo en errores
- Acceso a archivos: manejar estados HTTP 0/200 vs error

## Rendimiento
- Tiempos con `QS_PERF`
- Pre-generación de JSON por categoría/idioma
- Búsqueda cliente con resaltado eficiente

## Mantenimiento
- Nuevas categorías: crear subdirectorio y .md; detección automática
- Nuevos idiomas: extender validaciones y `get_language()` si aplica
- Depuración: ejecutar parsers y app en modo shell-only; usar `jq`

## Seguridad
- Acceso solo-lectura a `~/ddubsos/docs/`
- Sin red; QML en entorno controlado
- Manejo seguro de rutas y nombres

## Mejoras futuras
- Renderizado Markdown enriquecido con resaltado de sintaxis
- Exportación (PDF/HTML)
- Búsqueda avanzada (regex/indexado completo)
- Favoritos y marcadores
- Referencias cruzadas automáticas
- Integración con control de versiones (git)
- Watcher de archivos para auto-recarga

## Conclusión

La aplicación `qs-docs` proporciona una plataforma robusta para visualizar documentación técnica con búsqueda en tiempo real y soporte multilenguaje. Su arquitectura basada en sistema de archivos, capacidades de búsqueda eficiente e interfaz limpia la hacen ideal para gestionar documentación de proyectos, notas de desarrollo y guías técnicas. Su enfoque en flujos de trabajo para desarrolladores y documentación del sistema la convierte en una herramienta esencial para mantener bases de conocimiento técnico organizadas.

---

## Actualización 2025-09: Renderizado y búsqueda

Resumen:
- Markdown ahora se preconvierte a HTML con pandoc para mejorar la fidelidad (bloques de código, tablas, listas).
- El visor cambia a RichText con HTML pre-generado.
- Se reemplaza el resaltado inline por un panel de Coincidencias con saltos aproximados.
- Nuevas propiedades/modelos: `htmlContent`, `matchesModel`.

Detalles clave:
- Conversión en el lanzador: genera HTML en `$TMPDIR/html/<categoria>/<idioma>/<archivo>.html` a partir de los manifiestos `files_*.json`.
- QML carga markdown para buscar y HTML para mostrar (preferente), con respaldo `<pre>` escapado.
- Búsqueda: `updateSearch()` construye `matchesModel` con fragmentos, `jumpToMatch()` salta proporcionalmente usando `contentY`.
- Nix: escapar expansiones Bash como `''${var}` dentro de strings del script.

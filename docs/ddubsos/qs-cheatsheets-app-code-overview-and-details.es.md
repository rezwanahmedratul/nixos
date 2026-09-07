# qs-cheatsheets Aplicación: Documentación Técnica

## Resumen

La aplicación `qs-cheatsheets` es un visor de chuletas (cheatsheets) construido con QuickShell (Qt/QML) para mostrar y buscar documentación en Markdown del directorio `~/ddubsos/cheatsheets/`. Ofrece una interfaz unificada para navegar por categorías con búsqueda en tiempo real y soporte multilenguaje.

## Arquitectura

### Componentes principales

```
qs-cheatsheets/
├── modules/home/scripts/
│   ├── qs-cheatsheets.nix          # Script lanzador principal
│   └── cheatsheets-parser.nix      # Parser de archivos Markdown
└── modules/home/hyprland/
    └── windowrules.nix             # Reglas de ventana
```

### Pila tecnológica
- Shell: Bash con `set -euo pipefail`
- Parser: Bash + find/grep para procesar Markdown y generar JSON
- UI: Qt 6.x/QML con QuickShell
- Build: Nix (flake)
- WM: Hyprland con reglas personalizadas
- Formato de contenido: Archivos Markdown con soporte multilenguaje

## Estructura de archivos y código

### 1. Lanzador principal (`qs-cheatsheets.nix`)

Propósito: Analiza argumentos, descubre archivos y genera la interfaz QML.

CLI:
```bash
qs-cheatsheets [options]
  -c CATEGORY   (emacs|hyprland|kitty|wezterm|yazi|nixos) (por defecto: emacs)
  -l LANGUAGE   (en|es) (por defecto: en)
  -h            Ayuda
  --shell-only  Solo generar JSON (sin QML)

Variables de entorno:
  QS_PERF=1, QS_AUTO_QUIT=1, QS_SHELL_ONLY=1,
  CHEATSHEETS_CATEGORY, CHEATSHEETS_LANGUAGE
```

Validación de categoría (dinámica, incluye "root") y de idioma (en|es).

Pipeline de datos:
1) `mktemp -d`
2) JSON de ficheros (categoría/idioma) con cheatsheets-parser
3) JSON de categorías
4) Pre-generación para todas las categorías/idiomas
5) Generar QML y lanzar QuickShell

### 2. Parser de Markdown (`cheatsheets-parser.nix`)

Entrada:
```bash
cheatsheets-parser MODE [CATEGORY] [LANGUAGE]
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
- Datos: `cheatsheetFiles`, `availableCategories`, `filesModel`

Funciones clave:
- `loadCheatsheetFiles()` carga JSON pre-generado por categoría/idioma
- `loadFileContent(filename)` lee archivo via `file://`
- `updateSearch()` y `rebuildDisplayedContent()` realizan y resaltan coincidencias
- Cambios de categoría/idioma recargan la lista

### 4. Gestión de ventanas (Hyprland)

Reglas destacadas:
```nix
"float, class:^(org\\.qt-project\\.qml)$, title:^(Cheatsheets Viewer)$"
"center, class:^(org\\.qt-project\\.qml)$, title:^(Cheatsheets Viewer)$"
"noborder|noshadow|rounding 12|opacity 0.95 0.95 ..."
```

## Flujos de datos
- Inicialización: Comando → argumentos → validaciones → JSON → QML → QuickShell
- Generación: find → metadatos/título/idioma → JSON
- UI: onCompleted → XHR local (file://) → JSON.parse → modelo QML
- Contenido: selección → XHR → búsqueda → HTML resaltado

## Estructuras JSON
- Objeto de archivo: `filename`, `clean_name`, `title`, `category`, `language`, `path`
- Categorías: array de strings (incluye `root` si aplica)

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
- Acceso solo-lectura a `~/ddubsos/cheatsheets/`
- Sin red; QML en entorno controlado
- Manejo seguro de rutas y nombres

## Mejoras futuras
- Renderizado Markdown enriquecido y resaltado de sintaxis
- Exportación (PDF/HTML)
- Búsqueda avanzada (regex/fuzzy)
- Favoritos y marcadores
- Watcher de archivos para auto-recarga

---

## Actualización 2025-09: Renderizado y búsqueda

Resumen:
- Markdown ahora se preconvierte a HTML con pandoc (mejor fidelidad en bloques de código, tablas, listas y anidaciones).
- El visor cambia de MarkdownText a RichText y muestra el HTML generado.
- Se elimina el resaltado inline; en su lugar, un panel lateral de Coincidencias muestra fragmentos clicables y salto aproximado.
- Nuevas propiedades/modelos en QML: `htmlContent`, `matchesModel`.

Pipeline de renderizado (Markdown → HTML → RichText):
- En el inicio, el lanzador convierte todos los archivos .md referenciados en los manifiestos files_*.json a HTML en `$TMPDIR/html/<categoria>/<idioma>/<archivo>.html`.
- QML carga el markdown (para buscar) y el HTML (para mostrar). Si falta HTML, se usa `<pre>` escapado como respaldo.

Helper en Bash (nuevo):
```bash
convert_markdown_sets() {
  for json in "$tmpdir"/files_*.json; do
    [ -f "$json" ] || continue
    name=$(basename "$json")
    category="''${name#files_}"; category="''${category%_*}"
    language="''${name##*_}"; language="''${language%.json}"
    outdir="$tmpdir/html/$category/$language"
    ${pkgs.coreutils}/bin/mkdir -p "$outdir"
    while IFS= read -r src; do
      [ -n "$src" ] || continue
      base="$(basename "$src")"
      base_noext="''${base%.*}"
      out="$outdir/''${base_noext}.html"
      if ! ${pkgs.pandoc}/bin/pandoc -f gfm -t html5 --wrap=none "$src" -o "$out" 2>/dev/null; then
        esc=$(<"$src" ${pkgs.gnused}/bin/sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')
        printf '<pre style="white-space:pre-wrap;">%s</pre>' "$esc" > "$out"
      fi
    done < <(${pkgs.jq}/bin/jq -r '.[] | .path // empty' "$json" 2>/dev/null)
  done
}
```
Dependencias añadidas: pandoc, jq, sed.

Cambios en QML:
- Propiedades: `htmlContent` (HTML), `fileContent` (Markdown), `displayedContent` (lo que se muestra), `matchesModel` (lista de coincidencias).
- Preferir HTML al reconstruir la vista:
```js
function rebuildDisplayedContent() {
  if (!fileContent || fileContent.length === 0) { displayedContent = ""; return; }
  displayedContent = (htmlContent && htmlContent.length > 0)
    ? htmlContent
    : "<pre style=\\"white-space:pre-wrap;\\">" + escapeHtml(fileContent) + "</pre>";
}
```
- Visor cambia a TextEdit.RichText para mostrar HTML.
- Búsqueda: se construye `matchesModel` con fragmentos (~80 caracteres) y se usa salto aproximado proporcional a `start/length`.

Funciones clave (extracto):
```js
function updateSearch() {
  matchPositions = []; searchCount = 0; currentMatchIndex = 0; matchesModel.clear();
  if (!fileContent || !searchQuery || searchQuery.trim() === "") { rebuildDisplayedContent(); return; }
  const needle = String(searchQuery).toLowerCase(); const hay = String(fileContent).toLowerCase();
  let idx = 0, pos; while ((pos = hay.indexOf(needle, idx)) !== -1) { matchPositions.push([pos, pos+needle.length]); idx = pos+needle.length; }
  searchCount = matchPositions.length;
  for (let j=0; j<matchPositions.length; j++) { const s = matchPositions[j][0], e = matchPositions[j][1];
    const ctxStart = Math.max(0, s-80), ctxEnd = Math.min(fileContent.length, e+80);
    matchesModel.append({ idx: j, start: s, snippet: fileContent.slice(ctxStart, ctxEnd).replace(/\n/g, " ") });
  }
  currentMatchIndex = (searchCount > 0) ? 0 : 0; rebuildDisplayedContent();
}
function scrollToApproximatePosition(pos) {
  const flick = contentScroll && contentScroll.contentItem ? contentScroll.contentItem : null;
  if (!flick || !fileContent || fileContent.length === 0) return;
  const ratio = Math.max(0, Math.min(1, pos / fileContent.length));
  const maxY = Math.max(0, flick.contentHeight - contentScroll.height); flick.contentY = ratio * maxY;
}
function jumpToMatch(index) {
  if (searchCount <= 0) return; currentMatchIndex = Math.max(0, Math.min(searchCount-1, index));
  const start = matchPositions[currentMatchIndex][0]; scrollToApproximatePosition(start);
  if (typeof matchesList !== 'undefined' && matchesList) { matchesList.positionViewAtIndex(currentMatchIndex, ListView.Center); }
}
```

Notas:
- El salto aproximado es rápido pero no exacto al píxel; puede refinarse con anclas por encabezado.
- Si el HTML se ve "plano", verificar que pandoc esté disponible y que la conversión se haya ejecutado.
- En Nix, escapar expansiones Bash como `''${var}` dentro de strings.

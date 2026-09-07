# Aplicación qs-keybinds: Documentación Técnica

## Visión General

La aplicación `qs-keybinds` es un visor integral de combinaciones de teclas y configuraciones construido con QuickShell (Qt/QML) para mostrar y buscar datos de configuración de múltiples aplicaciones en una interfaz unificada. Soporta modos para gestores de ventanas y aplicaciones:
- Gestores de ventanas: Hyprland, Niri, DWM (botones renderizados condicionalmente según disponibilidad)
- Aplicaciones: Emacs, Kitty, WezTerm, Yazi y Cheatsheets

## Arquitectura

### Componentes Principales

```
qs-keybinds/
├── modules/home/scripts/
│   ├── qs-keybinds.nix          # Script lanzador principal
│   └── keybinds-parser.nix      # Analizadores de configuración
└── modules/home/hyprland/
    └── windowrules.nix          # Reglas de gestión de ventanas
```

### Stack Tecnológico
- **Shell**: Bash con `set -euo pipefail` para manejo estricto de errores
- **Analizador**: AWK para procesamiento de texto y generación de JSON
- **UI**: Qt 6.x/QML con runtime QuickShell
- **Sistema de Construcción**: Nix con configuración flake.nix
- **Gestor de Ventanas**: Hyprland con reglas de ventana personalizadas

## Estructura de Archivos y Diseño de Código

### 1. Lanzador Principal (`qs-keybinds.nix`)

El encabezado está dividido en dos filas:
- Fila superior: modos de gestor de ventanas (Hyprland, Niri, DWM)
- Segunda fila: vistas de aplicaciones (Emacs, Kitty, WezTerm, Yazi, Cheatsheets)

Los botones para los gestores de ventanas se muestran solo si están disponibles en el host, determinado por heurísticas y variables QS_HAS_* opcionales.

**Propósito**: Punto de entrada principal que maneja el análisis de argumentos, generación de datos y creación de la interfaz QML.

**Funciones Clave**:

#### Interfaz de Línea de Comandos
```bash
qs-keybinds [opciones]

Opciones:
  -m MODO    Modo a mostrar (hyprland|niri|dwm|emacs|kitty|wezterm|yazi|cheatsheets)
  -h         Mostrar ayuda
  
Flags especiales:
  --shell-only    Omitir interfaz QML, solo generar datos JSON
  
Variables de Entorno:
  QS_PERF=1          Habilitar salida de temporización de rendimiento
  QS_AUTO_QUIT=1     Auto-salir después de población del modelo (pruebas)
  QS_SHELL_ONLY=1    Omitir interfaz QML
  QS_HAS_NIRI=0|1    Forzar disponibilidad de Niri
  QS_HAS_HYPR=0|1    Forzar disponibilidad de Hyprland
  QS_HAS_DWM=0|1     Forzar disponibilidad de DWM
```

#### Funciones Principales

**Procesamiento de Argumentos**:
```bash
# Pre-manejar flags largos
ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --shell-only) QS_SHELL_ONLY=1; shift ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

# Procesar opciones cortas con getopts
while getopts ":m:h" opt; do
  case "$opt" in
    m) MODE="$OPTARG" ;;
    h) usage; exit 0 ;;
    :) echo "Argumento faltante para -$OPTARG" >&2; exit 2 ;;
    \?) echo "Opción desconocida -$OPTARG" >&2; usage; exit 2 ;;
  esac
done
```

**Validación de Modo**:
```bash
if [[ "$MODE" != "hyprland" && "$MODE" != "niri"  &&
      "$MODE" != "dwm" && "$MODE" != "emacs" && "$MODE" != "kitty" &&
      "$MODE" != "wezterm" && "$MODE" != "yazi" && "$MODE" != "cheatsheets" ]]; then
  echo "Error: Modo inválido '$MODE'" >&2
  exit 1
fi
```

**Pipeline de Generación de Datos**:
1. Crear directorio temporal con `mktemp - d`
2. Generar datos JSON primarios usando keybinds-parser
   - Si un modo no está disponible o el análisis falla, se escribe un arreglo vacío ([]) y se activa `modeAvailable`; la UI muestra un aviso informativo en lugar de salir.
3. Para aplicaciones multi-submodo (kitty/wezterm/yazi), generar archivos JSON adicionales:
   - `summary.json` - Visión general de configuración
   - `keybinds.json` - Combinaciones de teclas
   - `colors.json` - Temas de color
4. Crear archivo de interfaz QML con configuración embebida
5. Lanzar QuickShell con QML generado

**Monitoreo de Rendimiento**:
```bash
now_ms() { date +%s%3N; }
if [ -n "${QS_PERF:-}" ]; then 
  t1=$(now_ms)
  # ... operación
  t2=$(now_ms)
  echo "[perf] operacion_ms=$((t2 - t1))" >&2
fi
```

### 2. Analizador de Configuración (`keybinds-parser.nix`)

Analizadores y mejoras añadidas:
- Niri: analiza `~/.config/niri/config.kdl` (bloque binds)
- DWM: analiza `~/.config/suckless/sxhkd/sxhkdrc` (formato sxhkd)
- Manejo robusto de líneas en blanco/comentarios y omisión de comandos indentados vacíos en parsers sxhkd
- Normaliza nombres de modificadores y categoriza acciones

**Propósito**: Analizador de configuración multi-formato que extrae combinaciones de teclas y configuraciones de varios archivos de configuración de aplicaciones.

#### Arquitectura del Analizador

**Punto de Entrada**:
```bash
keybinds-parser MODO [SUBMODO]

MODO: hyprland|emacs|kitty|wezterm|yazi
SUBMODO: all|summary|keybinds|colors (para modos aplicables)
```

#### Analizadores Específicos por Modo

##### Analizador Hyprland
**Archivo**: `~/.config/hypr/hyprland.conf`
**Formato**: Sintaxis de configuración personalizada

**Lógica de Procesamiento Clave**:
```awk
/^bind[em]*=/ {
  # Analizar línea bind: bind=MODIFICADORES,TECLA,ACCIÓN,PARÁMETROS
  gsub(/^bind[em]*=/, "")
  split($0, parts, ",")
  
  if (length(parts) >= 3) {
    modifiers = parts[1]
    key = parts[2] 
    action = parts[3]
    # Unir partes restantes como parámetros
    params = ""
    for (i = 4; i <= length(parts); i++) {
      if (i > 4) params = params ","
      params = params parts[i]
    }
  }
}
```

**Lógica de Categorización**:
- Comandos `exec` → categorizados por tipo de aplicación
- `workspace`/`movetoworkspace` → gestión de espacios de trabajo
- `movewindow`/`swapwindow` → gestión de ventanas
- Acciones integradas → comandos del sistema hyprland

##### Analizador Emacs
**Archivo**: Datos JSON estáticos (teclas líderes Doom Emacs)
**Formato**: Mapeos de combinaciones de teclas predefinidos

**Categorías**:
- `files` - Operaciones de archivo (SPC f *)
- `buffers` - Gestión de buffers (SPC b *)
- `windows` - Divisiones/navegación de ventanas (SPC w *)
- `search` - Operaciones de búsqueda (SPC s *)
- `project` - Gestión de proyectos (SPC p *)
- `git` - Operaciones Git (SPC g *)
- `help` - Sistema de ayuda (SPC h *)
- `code` - Operaciones de código (SPC c *)
- `toggle` - Alternar características (SPC t *)
- `quit` - Operaciones de salida (SPC q *)

##### Analizador Kitty
**Archivo**: `~/.config/kitty/kitty.conf`
**Formato**: Configuración clave-valor con secciones

**Procesamiento de Submodos**:

*Modo Resumen*:
```awk
# Excluir comentarios, mapas y definiciones de color
!/^[ ]*#/ && !/^[ ]*map/ && !/^color[0-9]/ && 
!/^(fore|back|selection|cursor|url|active_|inactive_|tab_bar|mark[0-9])/ && NF > 0 {
  key = $1
  value = ""
  for (i = 2; i <= NF; i++) {
    if (i > 2) value = value " "
    value = value $i
  }
  
  # Categorización
  if (match(key, /font/)) category = "font"
  else if (match(key, /window/)) category = "window"
  # ... categorías adicionales
}
```

*Modo Colores*:
```awk
# Coincidir líneas con colores hex (incluyendo espacios)
/^[ ]*[a-zA-Z_][a-zA-Z0-9_]*[ ]+#[0-9a-fA-F]{6}/ {
  gsub(/^[ ]+/, "")
  key = $1
  value = $2
  
  # Categorización de color
  if (match(key, /^color[0-9]/)) {
    # Categorización de color ANSI
    if (match(key, /color[08]/)) category = "black"
    else if (match(key, /color[19]/)) category = "red"
    # ... colores ANSI adicionales
  }
  else if (match(key, /(active_tab|inactive_tab|tab_bar)/)) category = "tabs"
  # ... categorías de color adicionales
}
```

*Modo Combinaciones de Teclas*:
```awk
/^[ ]*map/ {
  gsub(/^[ ]*map[ ]+/, "")
  n = split($0, parts, /[ ]+/)
  
  if (n >= 2) {
    keybind = parts[1]
    action = parts[2]
    args = ""
    
    for (i = 3; i <= n; i++) {
      if (i > 3) args = args " "
      args = args parts[i]
    }
    
    # Formatear combinación de teclas (ctrl -> Ctrl, etc.)
    gsub(/ctrl/, "Ctrl", keybind)
    gsub(/shift/, "Shift", keybind)
    gsub(/alt/, "Alt", keybind)
    
    # Categorización
    if (match(action, /scroll/)) category = "scrolling"
    else if (match(action, /paste|copy/)) category = "clipboard"
    # ... categorías adicionales
  }
}
```

##### Analizador WezTerm  
**Archivo**: `~/.config/wezterm/wezterm.lua`
**Formato**: Configuración Lua

**Modo Resumen** - Análisis de Config Lua:
```awk
/^[ ]*config\./ {
  key = $0
  gsub(/^[ ]*config\./, "", key)
  gsub(/[ ,]+$/, "", key)
  
  # Dividir clave y valor en =
  split(key, kv, /=/)
  if (length(kv) >= 2) {
    k = kv[1]; v = kv[2]
    gsub(/^[ ]+|[ ]+$/, "", k)
    gsub(/^[ ]+|[ ]+$/, "", v)
    gsub(/^"|"$/, "", v)
    
    # Categorización
    if (k ~ /font|font_size/) cat = "font"
    else if (k ~ /window|opacity|padding/) cat = "window"
    else if (k ~ /cursor/) cat = "cursor"
    else cat = "general"
  }
}
```

**Modo Colores** - Extracción de Color Lua:
```awk
/config\.colors[ ]*=[ ]*\{/ { in_colors = 1; next }
in_colors && /\}/ { in_colors = 0 }

in_colors {
  # Coincidir entradas como key = "#hex"
  if (match(line, /([a-zA-Z_]+)[ ]*=[ ]*"#([0-9a-fA-F]{6})"/, m)) {
    k = m[1]; v = "#" m[2]; cat = "colors"
  }
  
  # Manejar tablas tab_bar anidadas
  if (line ~ /tab_bar[ ]*=[ ]*\{/) { in_tab = 1 }
  if (in_tab && match(line, /([a-zA-Z_]+)[ ]*=[ ]*"#([0-9a-fA-F]{6})"/, t)) {
    k = t[1]; v = "#" t[2]; cat = "tab_bar"
  }
}
```

**Modo Combinaciones de Teclas** - Análisis de Tabla de Teclas Lua:
```awk
/config\.keys[ ]*=[ ]*\{/ { in_keys = 1; next }
in_keys && /^[ ]*\}/ { in_keys = 0; next }

in_keys && /^[ ]*\{/ {
  # Extraer key, mods y action de tabla Lua
  if (match(line, /key[ ]*=[ ]*"([^"]+)"/, m1)) key = m1[1]
  if (match(line, /mods[ ]*=[ ]*"([^"]+)"/, m2)) mods = m2[1]
  if (match(line, /action[ ]*=[ ]*wezterm\.action\.([A-Za-z_]+)\(([^)]*)\)/, m3)) {
    action = m3[1]; args = m3[2]
  }
  
  # Construir cadena de combinación de teclas
  kb = ""; if (mods != "") kb = mods; 
  if (key != "") { 
    if (kb != "") kb = kb " + " key; 
    else kb = key 
  }
  
  # Normalizar nombres de modificadores
  gsub(/ALT/, "Alt", kb)
  gsub(/CTRL/, "Ctrl", kb)
  gsub(/SHIFT/, "Shift", kb)
}
```

### 3. Reglas de Ventana (`windowrules.nix`)

Se agregaron reglas para ventanas con título:
- "Niri Keybinds"
- "DWM Keybinds"

Cada una usa el mismo estilo/comportamiento que las ventanas de keybind existentes: flotar + centrar, noborder + noshadow, redondeo y opacidad.

##### Analizador Yazi
**Archivos**: `~/.config/yazi/keymap.toml`, `~/.config/yazi/theme.toml`  
**Formato**: Configuración TOML

**Modo Resumen** - Recolección de Estadísticas:
```awk
# Contar secciones de keymap y bindings
/^\\[\\[[a-zA-Z_]+\\.keymap\\]\\]/ { sections++; bindings++ }

# Contar colores de tema  
/fg = "#[0-9a-fA-F]{6}"/ { colors++ }
/bg = "#[0-9a-fA-F]{6}"/ { colors++ }

END {
  printf '{"setting":"keymap_sections","value":"%d sections","category":"keymaps"}', sections
  if (colors > 0) {
    print ","
    printf '{"setting":"theme_colors","value":"%d colors","category":"theme"}', colors
  }
  if (bindings > 0) {
    print ","
    printf '{"setting":"total_keybindings","value":"%d bindings","category":"keymaps"}', bindings
  }
}
```

**Modo Colores** - Extracción de Color TOML:
```awk
# Rastrear sección TOML actual
/^\\[([^\\[]*)\\]/ {
  gsub(/\\[|\\]/, "", $0)
  in_section = $0
  next
}

# Coincidir definiciones de color con valores hex
/^[a-zA-Z_]+ = .*#[0-9a-fA-F]{6}/ {
  if (match(line, /^([a-zA-Z_]+) = .*"(#[0-9a-fA-F]{6})"/, m)) {
    setting = m[1]
    color = m[2]
    
    # Determinar categoría basada en sección TOML
    cat = "theme"
    if (in_section == "mgr") cat = "manager"
    else if (in_section == "mode") cat = "mode"
    else if (in_section == "status") cat = "status"
    # ... mapeos de sección adicionales
  }
}
```

**Modo Combinaciones de Teclas** - Análisis de Keymap TOML:
```awk
# Coincidir secciones keymap como [[cmp.keymap]]
/^\\[\\[([a-zA-Z_]+)\\.keymap\\]\\]/ {
  gsub(/\\[\\[|\\]\\]/, "", $0)
  gsub(/\\.keymap/, "", $0)
  current_section = $0
  next
}

# Extraer entradas keymap dentro de secciones
current_section != "" {
  if (/^desc = /) {
    gsub(/^desc = "|"+$/, "", $0)
    desc = $0
  }
  else if (/^on = /) {
    gsub(/^on = "|"+$/, "", $0)
    keybind = $0
    # Convertir notación de tecla
    gsub(/<C-/, "Ctrl+", keybind)
    gsub(/<A-/, "Alt+", keybind)
    gsub(/<S-/, "Shift+", keybind)
    gsub(/</, "", keybind)
    gsub(/>/, "", keybind)
  }
  else if (/^run = / && keybind != "" && desc != "") {
    gsub(/^run = "|"+$/, "", $0)
    action = $0
    
    # Construir descripción
    description = desc
    if (action != "" && action != desc) description = desc " (" action ")"
    
    # Determinar categoría basada en sección
    if (current_section == "manager") cat = "file-management"
    else if (current_section == "cmp") cat = "completion"
    else if (current_section == "confirm") cat = "dialogs"
    # ... mapeos de sección adicionales
  }
}
```

### 3. Interfaz de Usuario QML

**Arquitectura**: Aplicación QML de archivo único con lógica JavaScript embebida

#### Propiedades Principales
```javascript
property bool perfEnabled: $PERF_BOOL
property bool autoQuit: $AUTO_QUIT_BOOL
property string searchQuery: ""
property string selectedMode: "$MODE"
property string selectedCategory: "all"
property string selectedSubMode: "all"
property var keybindsData: []
property bool dataLoaded: false
property string jsonDataFile: "$json"
```

#### Funciones Clave

**Carga de Datos**:
```javascript
function loadKeybindsData() {
  if (dataLoaded) return;
  
  const xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function() {
    if (xhr.readyState === XMLHttpRequest.DONE) {
      if (xhr.status === 200 || xhr.status === 0) {
        try {
          const result = JSON.parse(xhr.responseText);
          win.keybindsData = result;
          win.dataLoaded = true;
          win.selectedCategory = "all";
          win.populateModel(win.keybindsData);
        } catch (e) {
          console.error("Error al analizar JSON de keybinds:", e);
        }
      }
    }
  };
  xhr.open("GET", "file://" + jsonDataFile);
  xhr.send();
}
```

**Carga de Datos de Submodo**:
```javascript
function loadKeybindsDataWithSubMode(submode) {
  console.log("Cargando submodo:", submode);
  
  // Determinar qué archivo JSON cargar basado en submodo
  var fileName = "keybinds.json";
  if (submode === "summary") fileName = "summary.json";
  else if (submode === "keybinds") fileName = "keybinds.json";
  else if (submode === "colors") fileName = "colors.json";
  
  var filePath = jsonDataFile.replace("keybinds.json", fileName);
  
  const xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function() {
    if (xhr.readyState === XMLHttpRequest.DONE) {
      if (xhr.status === 200 || xhr.status === 0) {
        try {
          let result = JSON.parse(xhr.responseText);
          // Normalizar datos summary/colors a { keybind, description, category }
          if (Array.isArray(result) && result.length > 0 && result[0].setting !== undefined) {
            result = result.map(function(it) {
              return {
                keybind: it.setting,
                description: it.value,
                category: it.category || "general"
              };
            });
          }
          win.keybindsData = result;
          win.selectedSubMode = submode;
          win.populateModel(result);
        } catch (e) {
          console.error("Error al analizar JSON de submodo:", e);
        }
      }
    }
  };
  xhr.open("GET", "file://" + filePath);
  xhr.send();
}
```

**Lógica de Filtrado**:
```javascript
function filterKeybinds(q, category) {
  let filtered = keybindsData;
  
  // Aplicar filtro de categoría primero
  if (category && category !== "all") {
    filtered = filtered.filter(it => it.category === category);
  }
  
  // Luego aplicar filtro de búsqueda
  if (q && q.trim() !== "") {
    const s = q.toLowerCase();
    filtered = filtered.filter(it =>
      (it.keybind && it.keybind.toLowerCase().indexOf(s) !== -1) ||
      (it.description && it.description.toLowerCase().indexOf(s) !== -1) ||
      (it.category && it.category.toLowerCase().indexOf(s) !== -1)
    );
  }
  
  return filtered;
}
```

**Gestión de Categorías**:
```javascript
function getCategories() {
  // Para modos Kitty, WezTerm y Yazi, mostrar sub-modos específicos de aplicación
  if (selectedMode === "kitty" || selectedMode === "wezterm" || selectedMode === "yazi") {
    return ["all", "summary", "keybinds", "colors"];
  }
  
  // Para otros modos, extraer categorías de datos
  const cats = new Set(["all"]);
  keybindsData.forEach(it => {
    if (it.category) cats.add(it.category);
  });
  return Array.from(cats).sort((a, b) => {
    if (a === "all") return -1;
    if (b === "all") return 1;
    return a.localeCompare(b);
  });
}
```

**Visualización de Muestra de Color**:
```qml
// Muestra de color (solo para valores de color hex)
Rectangle {
  width: 32
  height: 24
  radius: 4
  color: (model.description && model.description.match && 
          model.description.match(/^#[0-9a-fA-F]{6}$/)) ? 
         model.description : "transparent"
  border.width: (model.description && model.description.match && 
                 model.description.match(/^#[0-9a-fA-F]{6}$/)) ? 1 : 0
  border.color: "#666666"
  visible: (model.description && model.description.match && 
            model.description.match(/^#[0-9a-fA-F]{6}$/))
}
```

**Mapeo de Nombres de Color**:
```javascript
function getColorName(hexColor) {
  if (!hexColor || !hexColor.match(/^#[0-9a-fA-F]{6}$/)) return "";
  
  const hex = hexColor.toLowerCase();
  
  // Mapeos de color tema Catppuccin
  const colorNames = {
    "#1e1e2e": "(base)",
    "#11111b": "(crust)", 
    "#cdd6f4": "(text)",
    "#f5e0dc": "(rosewater)",
    "#b4befe": "(lavender)",
    "#f9e2af": "(yellow)",
    "#cba6f7": "(mauve)",
    "#a6e3a1": "(green)",
    "#89b4fa": "(blue)",
    // ... mapeos adicionales
  };
  
  return colorNames[hex] || "";
}
```

### 4. Gestión de Ventanas (`windowrules.nix`)

**Propósito**: Reglas de ventana Hyprland para comportamiento de flotación apropiado y estilo

**Categorías de Reglas**:

*Reglas de Flotación*:
```nix
"float, class:^(org\\.qt-project\\.qml)$, title:^(Hyprland Keybinds)$"
"float, class:^(org\\.qt-project\\.qml)$, title:^(Emacs Leader Keybinds)$"  
"float, class:^(org\\.qt-project\\.qml)$, title:^(Kitty Configuration)$"
"float, class:^(org\\.qt-project\\.qml)$, title:^(WezTerm Configuration)$"
"float, class:^(org\\.qt-project\\.qml)$, title:^(Yazi Configuration)$"
```

*Reglas de Centrado*:
```nix
"center, class:^(org\\.qt-project\\.qml)$, title:^(Hyprland Keybinds)$"
"center, class:^(org\\.qt-project\\.qml)$, title:^(Emacs Leader Keybinds)$"
# ... reglas de centrado adicionales para cada modo
```

*Reglas de Estilo (windowrulev2)*:
```nix
"noborder, class:^(org\\.qt-project\\.qml)$, title:^(Hyprland Keybinds)$"
"noshadow, class:^(org\\.qt-project\\.qml)$, title:^(Hyprland Keybinds)$" 
"rounding 12, class:^(org\\.qt-project\\.qml)$, title:^(Hyprland Keybinds)$"
"opacity 0.95 0.95, class:^(org\\.qt-project\\.qml)$, title:^(Hyprland Keybinds)$"
# ... replicado para cada modo
```

## Arquitectura de Flujo de Datos

### 1. Flujo de Inicialización
```
Comando del Usuario → Análisis de Argumentos → Validación de Modo → 
Creación de Directorio Temporal → Generación de Datos → 
Creación de Interfaz QML → Lanzamiento de QuickShell
```

### 2. Flujo de Generación de Datos
```
keybinds-parser MODO [SUBMODO] →
Procesamiento AWK → Análisis de Archivo de Configuración →
Generación de Estructura JSON → Salida de Archivo
```

### 3. Flujo de Datos UI
```
QML Component.onCompleted → loadKeybindsData() →
XMLHttpRequest → JSON.parse() → Población de Modelo →
Extracción de Categoría → Renderizado de UI
```

### 4. Flujo de Cambio de Submodo  
```
Clic de Botón de Categoría → loadKeybindsDataWithSubMode() →
Ruta de Archivo Dinámica → XMLHttpRequest → Normalización de Datos →
Actualización de Modelo → Refresco de UI
```

## Estructuras de Datos JSON

### Objeto Keybind Estándar
```json
{
  "keybind": "Super + t",
  "description": "Ejecutar: kitty",  
  "category": "terminal"
}
```

### Objeto Resumen/Colores (Normalizado)
```json
{
  "setting": "font_size",
  "value": "12",
  "category": "font"
}
```

### Objeto Color con Valor Hex
```json
{
  "setting": "foreground",
  "value": "#cdd6f4",
  "category": "basic"
}
```

## Sistema de Categorías

### Categorías Principales (Hyprland)
- `terminal` - Aplicaciones de terminal
- `editor` - Editores de texto e IDEs
- `launcher` - Lanzadores de aplicaciones
- `browser` - Navegadores web
- `screenshot` - Herramientas de captura de pantalla
- `wallpaper` - Gestión de fondos de pantalla
- `media` - Volumen, brillo, controles de audio
- `window` - Acciones de gestión de ventanas
- `workspace` - Operaciones de espacio de trabajo
- `hyprland` - Funciones integradas de Hyprland
- `app` - Aplicaciones genéricas

### Categorías Específicas de Terminal

**Kitty/WezTerm**:
- `font` - Configuración de fuente
- `window` - Apariencia de ventana
- `colors` - Esquema de colores
- `cursor` - Configuraciones de cursor
- `scrolling` - Comportamiento de desplazamiento
- `tabs` - Gestión de pestañas
- `panes` - Operaciones de paneles
- `clipboard` - Operaciones de copiar/pegar

**Yazi**:
- `manager` - Operaciones del gestor de archivos
- `completion` - Auto-completado
- `dialogs` - Diálogos de confirmación
- `input` - Modos de entrada de texto
- `file-management` - Operaciones de archivo
- `theme` - Tematización visual
- `keymaps` - Configuración de keymap

## Manejo de Errores

### Manejo de Errores de Script Shell
```bash
set -euo pipefail  # Manejo estricto de errores

# Validación con errores informativos
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: Archivo de configuración no encontrado en $CONFIG_FILE" >&2
  exit 1
fi

# Validación de modo  
if [[ "$MODE" != "hyprland" && "$MODE" != "emacs" && ... ]]; then
  echo "Error: Modo inválido '$MODE'. Use 'hyprland', 'emacs', 'kitty', 'wezterm', or 'yazi'" >&2
  exit 1
fi
```

### Manejo de Errores QML
```javascript
try {
  const result = JSON.parse(xhr.responseText);
  win.keybindsData = result;
  win.dataLoaded = true;
  win.populateModel(win.keybindsData);
} catch (e) {
  console.error("Error al analizar JSON de keybinds:", e);
  win.keybindsData = [];
  win.dataLoaded = true;  
  win.populateModel([]);
}
```

### Prevención de Errores AWK
```awk
# Acceso seguro a array
if (length(parts) >= 3) {
  # Procesar partes de forma segura
}

# Escape JSON
gsub(/\\/, "\\\\\\\\", keybind)
gsub(/"/, "\\\\\\"", keybind)

# Validación de campo
if (keybind != "" && description != "") {
  # Salida JSON
}
```

## Consideraciones de Rendimiento

### Temporización y Perfilado
```bash
# Monitoreo de rendimiento
now_ms() { date +%s%3N; }

if [ -n "${QS_PERF:-}" ]; then
  t1=$(now_ms)
  # Operación
  t2=$(now_ms) 
  echo "[perf] json_ms=$((t2 - t1))" >&2
fi
```

### Estrategias de Optimización

**Generación de Datos**:
- Procesamiento AWK de una sola pasada
- Creación mínima de archivos temporales
- Generación eficiente de estructura JSON
- Archivos de submodo pre-generados para cambio más rápido

**Rendimiento de UI**:
- Carga de datos perezosa con XMLHttpRequest
- Filtrado del lado del cliente para búsqueda receptiva
- Población de modelo con seguimiento de progreso
- Manipulación DOM mínima en QML

**Gestión de Memoria**:
- Limpieza de directorio temporal
- Manejo eficiente de objetos JavaScript
- Retención limitada de datos en memoria

## Guía de Mantenimiento

### Agregar Nuevos Modos

1. **Actualizar Validación de Modo**:
```bash
# En qs-keybinds.nix
if [[ "$MODE" != "hyprland" && "$MODE" != "emacs" && ... && "$MODE" != "newmode" ]]; then
```

2. **Agregar Lógica de Analizador**:
```bash
# En keybinds-parser.nix  
newmode)
  CONFIG_FILE="$HOME/.config/newmode/config"
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config no encontrado" >&2
    exit 1
  fi
  
  case "$SUBMODE" in
    summary) # ... ;;
    colors) # ... ;;  
    *) # keybinds ... ;;
  esac
  ;;
```

3. **Actualizar Lógica UI**:
```javascript
// Agregar a función getCategories()
if (selectedMode === "kitty" || selectedMode === "wezterm" || 
    selectedMode === "yazi" || selectedMode === "newmode") {
  return ["all", "summary", "keybinds", "colors"];
}

// Agregar a manejador de clic de botón
if ((win.selectedMode === "kitty" || win.selectedMode === "wezterm" || 
     win.selectedMode === "yazi" || win.selectedMode === "newmode") && 
    modelData !== "all") {
```

4. **Agregar Reglas de Ventana**:
```nix
# En windowrules.nix
"float, class:^(org\\.qt-project\\.qml)$, title:^(NewMode Configuration)$"
"center, class:^(org\\.qt-project\\.qml)$, title:^(NewMode Configuration)$"
# ... reglas de estilo
```

5. **Agregar Botón UI**:
```qml
Button {
  text: "NewMode"  
  width: 120
  height: 36
  // ... estilo y manejador de clic
}
```

### Procedimientos de Depuración

**Depuración de Analizador**:
```bash
# Probar analizador directamente
keybinds-parser newmode summary | jq '.'
keybinds-parser newmode keybinds | jq 'length'
keybinds-parser newmode colors | jq '.[0:3]'

# Modo solo shell para pruebas
QS_SHELL_ONLY=1 qs-keybinds -m newmode
```

**Depuración de Rendimiento**:
```bash
# Habilitar salida de rendimiento
QS_PERF=1 qs-keybinds -m newmode

# Auto-salir para pruebas
QS_AUTO_QUIT=1 qs-keybinds -m newmode
```

**Depuración de UI**:
- Revisar consola del navegador para errores JavaScript
- Verificar estructura JSON con `jq`
- Probar acceso de archivo XMLHttpRequest
- Validar sintaxis QML con QuickShell

### Problemas Comunes y Soluciones

**Problema**: Datos de submodo vacíos
**Solución**: Revisar rutas de archivo, patrones regex AWK y escape JSON

**Problema**: UI no actualiza al cambiar categoría
**Solución**: Verificar función `loadKeybindsDataWithSubMode()` y construcción de ruta de archivo

**Problema**: Ventana no flota
**Solución**: Agregar reglas de ventana apropiadas en `windowrules.nix`

**Problema**: Búsqueda no funciona
**Solución**: Revisar función `filterKeybinds()` y asegurar estructura de datos apropiada

## Construcción e Implementación

### Proceso de Construcción Nix
```bash
# Construcción de desarrollo
sudo nixos-rebuild switch --flake .

# Verificar disponibilidad de script  
which qs-keybinds
which keybinds-parser

# Probar modos
qs-keybinds -m hyprland
qs-keybinds -m kitty
```

### Dependencias
- `pkgs.gawk` - Procesamiento AWK
- `pkgs.jq` - Procesamiento JSON (pruebas de analizador)
- `pkgs.coreutils` - Utilidades Date, mktemp
- Runtime QuickShell - Interfaz QML
- Qt 6.x - Framework UI

### Archivos de Configuración
La aplicación lee de ubicaciones de configuración estándar:
- `~/.config/hypr/hyprland.conf`
- `~/.config/kitty/kitty.conf`  
- `~/.config/wezterm/wezterm.lua`
- `~/.config/yazi/keymap.toml`
- `~/.config/yazi/theme.toml`

## Consideraciones de Seguridad

### Validación de Entrada
- Validación de parámetro de modo contra valores permitidos
- Validación de ruta de archivo para archivos de configuración
- Escape JSON para prevenir inyección

### Acceso a Archivo
- Acceso solo de lectura a archivos de configuración
- Directorio temporal con permisos apropiados
- No se requiere acceso de red externo

### Contexto de Ejecución
- Ejecuta en contexto de usuario, sin escalada de privilegios
- Entorno de ejecución QML en sandbox
- No hay ejecución de código arbitrario desde archivos de configuración

## Mejoras Futuras

### Mejoras Potenciales
1. **Recarga en Caliente de Configuración**: Observar archivos de config para cambios
2. **Funcionalidad de Exportación**: Exportar resultados filtrados a varios formatos
3. **Categorías Personalizadas**: Mapeos de categoría definidos por usuario
4. **Búsqueda Difusa**: Búsqueda mejorada con coincidencia difusa
5. **Temas**: Temas UI personalizables y esquemas de color
6. **Sistema de Plugins**: Arquitectura de analizador extensible
7. **Validación de Configuración**: Verificación de sintaxis para archivos config
8. **Respaldo/Restauración**: Herramientas de respaldo y restauración de configuración

### Escalabilidad de Arquitectura
- El diseño modular del analizador permite extensión fácil
- La arquitectura de componentes QML soporta características UI adicionales  
- El formato de datos JSON proporciona intercambio de datos flexible
- El sistema de construcción Nix habilita implementaciones reproducibles

## Conclusión

La aplicación `qs-keybinds` proporciona una plataforma integral y extensible para gestión de configuración y visualización de combinaciones de teclas. Su arquitectura modular, manejo robusto de errores y optimización de rendimiento la hacen adecuada tanto para uso individual como escenarios de implementación en equipo. La documentación detallada y los procedimientos de mantenimiento aseguran sostenibilidad a largo plazo y facilidad de mejora.
# qs-keybinds Application: Technical Documentation

## Overview

The `qs-keybinds` application is a comprehensive keybinds and configuration viewer built with QuickShell (Qt/QML) for displaying and searching configuration data from multiple applications in a unified interface. It supports modes for window managers and applications:
- Window managers: Hyprland, Niri, DWM (buttons rendered conditionally by availability)
- Applications: Emacs, Kitty, WezTerm, Yazi, and Cheatsheets

## Architecture

### Core Components

```
qs-keybinds/
├── modules/home/scripts/
│   ├── qs-keybinds.nix          # Main launcher script
│   └── keybinds-parser.nix      # Configuration parsers
└── modules/home/hyprland/
    └── windowrules.nix          # Window management rules
```

### Technology Stack
- **Shell**: Bash with `set -euo pipefail` for strict error handling
- **Parser**: AWK for text processing and JSON generation
- **UI**: Qt 6.x/QML with QuickShell runtime
- **Build System**: Nix with flake.nix configuration
- **Window Manager**: Hyprland with custom window rules

## File Structure and Code Layout

### 1. Main Launcher (`qs-keybinds.nix`)

Header layout is split into two rows:
- Top row: window manager modes (Hyprland, Niri, DWM)
- Second row: app views (Emacs, Kitty, WezTerm, Yazi, Cheatsheets)

Buttons for WM modes are shown only if available on the host, determined by heuristics and optional QS_HAS_* overrides.

**Purpose**: Primary entry point that handles argument parsing, data generation, and QML interface creation.

**Key Functions**:

#### Command Line Interface
```bash
qs-keybinds [options]

Options:
  -m MODE    Mode to display (hyprland|niri|dwm|emacs|kitty|wezterm|yazi|cheatsheets)
  -h         Show help
  
Special flags:
  --shell-only    Skip QML interface, only generate JSON data
  
Environment Variables:
  QS_PERF=1          Enable performance timing output
  QS_AUTO_QUIT=1     Auto-quit after model population (testing)
  QS_SHELL_ONLY=1    Skip QML interface
  QS_HAS_NIRI=0|1    Override Niri availability detection
  QS_HAS_HYPR=0|1    Override Hyprland availability detection
  QS_HAS_DWM=0|1     Override DWM availability detection
```

#### Core Functions

**Argument Processing**:
```bash
# Pre-handle long flags
ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --shell-only) QS_SHELL_ONLY=1; shift ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

# Process short options with getopts
while getopts ":m:h" opt; do
  case "$opt" in
    m) MODE="$OPTARG" ;;
    h) usage; exit 0 ;;
    :) echo "Missing argument for -$OPTARG" >&2; exit 2 ;;
    \?) echo "Unknown option -$OPTARG" >&2; usage; exit 2 ;;
  esac
done
```

**Mode Validation**:
```bash
if [[ "$MODE" != "hyprland" && "$MODE" != "niri"  &&
      "$MODE" != "dwm" && "$MODE" != "emacs" && "$MODE" != "kitty" &&
      "$MODE" != "wezterm" && "$MODE" != "yazi" && "$MODE" != "cheatsheets" ]]; then
  echo "Error: Invalid mode '$MODE'" >&2
  exit 1
fi
```

**Data Generation Pipeline**:
1. Create temporary directory with `mktemp -d`
2. Generate primary JSON data using keybinds-parser
   - If a mode is unavailable or parsing fails, an empty array ([]) is written and `modeAvailable` is set; the UI will display an informational banner instead of exiting.
3. For multi-submode apps (kitty/wezterm/yazi), generate additional JSON files:
   - `summary.json` - Configuration overview
   - `keybinds.json` - Key bindings
   - `colors.json` - Color themes
4. Create QML interface file with embedded configuration
5. Launch QuickShell with generated QML

**Performance Monitoring**:
```bash
now_ms() { date +%s%3N; }
if [ -n "${QS_PERF:-}" ]; then 
  t1=$(now_ms)
  # ... operation
  t2=$(now_ms)
  echo "[perf] operation_ms=$((t2 - t1))" >&2
fi
```

### 2. Configuration Parser (`keybinds-parser.nix`)

Added WM parsers and improvements:
- Niri: parses `~/.config/niri/config.kdl` (binds block)
- DWM: parses `~/.config/suckless/sxhkd/sxhkdrc` (sxhkd format)
- Robust blank-line/comment handling and empty-command skipping in sxhkd parsers
- Normalizes modifier names and categorizes actions

**Purpose**: Multi-format configuration parser that extracts keybinds and settings from various application configuration files.

#### Parser Architecture

**Entry Point**:
```bash
keybinds-parser MODE [SUBMODE]

MODE: hyprland|emacs|kitty|wezterm|yazi
SUBMODE: all|summary|keybinds|colors (for applicable modes)
```

#### Mode-Specific Parsers

##### Hyprland Parser
**File**: `~/.config/hypr/hyprland.conf`
**Format**: Custom configuration syntax

**Key Processing Logic**:
```awk
/^bind[em]*=/ {
  # Parse bind line: bind=MODIFIERS,KEY,ACTION,PARAMS
  gsub(/^bind[em]*=/, "")
  split($0, parts, ",")
  
  if (length(parts) >= 3) {
    modifiers = parts[1]
    key = parts[2] 
    action = parts[3]
    # Join remaining parts as parameters
    params = ""
    for (i = 4; i <= length(parts); i++) {
      if (i > 4) params = params ","
      params = params parts[i]
    }
  }
}
```

**Categorization Logic**:
- `exec` commands → categorized by application type
- `workspace`/`movetoworkspace` → workspace management  
- `movewindow`/`swapwindow` → window management
- Built-in actions → hyprland system commands

##### Emacs Parser
**File**: Static JSON data (Doom Emacs leader keys)
**Format**: Predefined keybind mappings

**Categories**:
- `files` - File operations (SPC f *)
- `buffers` - Buffer management (SPC b *)
- `windows` - Window splits/navigation (SPC w *)
- `search` - Search operations (SPC s *)
- `project` - Project management (SPC p *)
- `git` - Git operations (SPC g *)
- `help` - Help system (SPC h *)
- `code` - Code operations (SPC c *)
- `toggle` - Toggle features (SPC t *)
- `quit` - Exit operations (SPC q *)

##### Kitty Parser
**File**: `~/.config/kitty/kitty.conf`
**Format**: Key-value configuration with sections

**Submode Processing**:

*Summary Mode*:
```awk
# Exclude comments, maps, and color definitions
!/^[ ]*#/ && !/^[ ]*map/ && !/^color[0-9]/ && 
!/^(fore|back|selection|cursor|url|active_|inactive_|tab_bar|mark[0-9])/ && NF > 0 {
  key = $1
  value = ""
  for (i = 2; i <= NF; i++) {
    if (i > 2) value = value " "
    value = value $i
  }
  
  # Categorization
  if (match(key, /font/)) category = "font"
  else if (match(key, /window/)) category = "window"
  # ... additional categories
}
```

*Colors Mode*:
```awk
# Match lines with hex colors (including whitespace)
/^[ ]*[a-zA-Z_][a-zA-Z0-9_]*[ ]+#[0-9a-fA-F]{6}/ {
  gsub(/^[ ]+/, "")
  key = $1
  value = $2
  
  # Color categorization
  if (match(key, /^color[0-9]/)) {
    # ANSI color categorization
    if (match(key, /color[08]/)) category = "black"
    else if (match(key, /color[19]/)) category = "red"
    # ... additional ANSI colors
  }
  else if (match(key, /(active_tab|inactive_tab|tab_bar)/)) category = "tabs"
  # ... additional color categories
}
```

*Keybinds Mode*:
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
    
    # Format keybind (ctrl -> Ctrl, etc.)
    gsub(/ctrl/, "Ctrl", keybind)
    gsub(/shift/, "Shift", keybind)
    gsub(/alt/, "Alt", keybind)
    
    # Categorization
    if (match(action, /scroll/)) category = "scrolling"
    else if (match(action, /paste|copy/)) category = "clipboard"
    # ... additional categories
  }
}
```

##### WezTerm Parser  
**File**: `~/.config/wezterm/wezterm.lua`
**Format**: Lua configuration

**Summary Mode** - Lua Config Parsing:
```awk
/^[ ]*config\./ {
  key = $0
  gsub(/^[ ]*config\./, "", key)
  gsub(/[ ,]+$/, "", key)
  
  # Split key and value on =
  split(key, kv, /=/)
  if (length(kv) >= 2) {
    k = kv[1]; v = kv[2]
    gsub(/^[ ]+|[ ]+$/, "", k)
    gsub(/^[ ]+|[ ]+$/, "", v)
    gsub(/^"|"$/, "", v)
    
    # Categorization
    if (k ~ /font|font_size/) cat = "font"
    else if (k ~ /window|opacity|padding/) cat = "window"
    else if (k ~ /cursor/) cat = "cursor"
    else cat = "general"
  }
}
```

**Colors Mode** - Lua Color Extraction:
```awk
/config\.colors[ ]*=[ ]*\{/ { in_colors = 1; next }
in_colors && /\}/ { in_colors = 0 }

in_colors {
  # Match entries like key = "#hex"
  if (match(line, /([a-zA-Z_]+)[ ]*=[ ]*"#([0-9a-fA-F]{6})"/, m)) {
    k = m[1]; v = "#" m[2]; cat = "colors"
  }
  
  # Handle nested tab_bar tables
  if (line ~ /tab_bar[ ]*=[ ]*\{/) { in_tab = 1 }
  if (in_tab && match(line, /([a-zA-Z_]+)[ ]*=[ ]*"#([0-9a-fA-F]{6})"/, t)) {
    k = t[1]; v = "#" t[2]; cat = "tab_bar"
  }
}
```

**Keybinds Mode** - Lua Key Table Parsing:
```awk
/config\.keys[ ]*=[ ]*\{/ { in_keys = 1; next }
in_keys && /^[ ]*\}/ { in_keys = 0; next }

in_keys && /^[ ]*\{/ {
  # Extract key, mods, and action from Lua table
  if (match(line, /key[ ]*=[ ]*"([^"]+)"/, m1)) key = m1[1]
  if (match(line, /mods[ ]*=[ ]*"([^"]+)"/, m2)) mods = m2[1]
  if (match(line, /action[ ]*=[ ]*wezterm\.action\.([A-Za-z_]+)\(([^)]*)\)/, m3)) {
    action = m3[1]; args = m3[2]
  }
  
  # Build keybind string
  kb = ""; if (mods != "") kb = mods; 
  if (key != "") { 
    if (kb != "") kb = kb " + " key; 
    else kb = key 
  }
  
  # Normalize modifier names
  gsub(/ALT/, "Alt", kb)
  gsub(/CTRL/, "Ctrl", kb)
  gsub(/SHIFT/, "Shift", kb)
}
```

### 3. Window Rules (`windowrules.nix`)

Added rules for windows titled:
- "Niri Keybinds"
- "DWM Keybinds"

Each uses the same styling/behavior as existing keybind windows: float + center, noborder + noshadow, rounding, and opacity.

##### Yazi Parser
**Files**: `~/.config/yazi/keymap.toml`, `~/.config/yazi/theme.toml`  
**Format**: TOML configuration

**Summary Mode** - Statistics Collection:
```awk
# Count keymap sections and bindings
/^\\[\\[[a-zA-Z_]+\\.keymap\\]\\]/ { sections++; bindings++ }

# Count theme colors  
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

**Colors Mode** - TOML Color Extraction:
```awk
# Track current TOML section
/^\\[([^\\[]*)\\]/ {
  gsub(/\\[|\\]/, "", $0)
  in_section = $0
  next
}

# Match color definitions with hex values
/^[a-zA-Z_]+ = .*#[0-9a-fA-F]{6}/ {
  if (match(line, /^([a-zA-Z_]+) = .*"(#[0-9a-fA-F]{6})"/, m)) {
    setting = m[1]
    color = m[2]
    
    # Determine category based on TOML section
    cat = "theme"
    if (in_section == "mgr") cat = "manager"
    else if (in_section == "mode") cat = "mode"
    else if (in_section == "status") cat = "status"
    # ... additional section mappings
  }
}
```

**Keybinds Mode** - TOML Keymap Parsing:
```awk
# Match keymap sections like [[cmp.keymap]]
/^\\[\\[([a-zA-Z_]+)\\.keymap\\]\\]/ {
  gsub(/\\[\\[|\\]\\]/, "", $0)
  gsub(/\\.keymap/, "", $0)
  current_section = $0
  next
}

# Extract keymap entries within sections
current_section != "" {
  if (/^desc = /) {
    gsub(/^desc = "|"+$/, "", $0)
    desc = $0
  }
  else if (/^on = /) {
    gsub(/^on = "|"+$/, "", $0)
    keybind = $0
    # Convert key notation
    gsub(/<C-/, "Ctrl+", keybind)
    gsub(/<A-/, "Alt+", keybind)
    gsub(/<S-/, "Shift+", keybind)
    gsub(/</, "", keybind)
    gsub(/>/, "", keybind)
  }
  else if (/^run = / && keybind != "" && desc != "") {
    gsub(/^run = "|"+$/, "", $0)
    action = $0
    
    # Build description
    description = desc
    if (action != "" && action != desc) description = desc " (" action ")"
    
    # Determine category based on section
    if (current_section == "manager") cat = "file-management"
    else if (current_section == "cmp") cat = "completion"
    else if (current_section == "confirm") cat = "dialogs"
    # ... additional section mappings
  }
}
```

### 3. QML User Interface

**Architecture**: Single-file QML application with embedded JavaScript logic

#### Core Properties
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

#### Key Functions

**Data Loading**:
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
          console.error("Failed to parse keybinds JSON:", e);
        }
      }
    }
  };
  xhr.open("GET", "file://" + jsonDataFile);
  xhr.send();
}
```

**Submode Data Loading**:
```javascript
function loadKeybindsDataWithSubMode(submode) {
  console.log("Loading submode:", submode);
  
  // Determine which JSON file to load based on submode
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
          // Normalize summary/colors data into { keybind, description, category }
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
          console.error("Failed to parse submode JSON:", e);
        }
      }
    }
  };
  xhr.open("GET", "file://" + filePath);
  xhr.send();
}
```

**Filtering Logic**:
```javascript
function filterKeybinds(q, category) {
  let filtered = keybindsData;
  
  // Apply category filter first
  if (category && category !== "all") {
    filtered = filtered.filter(it => it.category === category);
  }
  
  // Then apply search filter
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

**Category Management**:
```javascript
function getCategories() {
  // For Kitty, WezTerm, and Yazi modes, show app-specific sub-modes
  if (selectedMode === "kitty" || selectedMode === "wezterm" || selectedMode === "yazi") {
    return ["all", "summary", "keybinds", "colors"];
  }
  
  // For other modes, extract categories from data
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

**Color Swatch Display**:
```qml
// Color swatch (only for hex color values)
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

**Color Name Mapping**:
```javascript
function getColorName(hexColor) {
  if (!hexColor || !hexColor.match(/^#[0-9a-fA-F]{6}$/)) return "";
  
  const hex = hexColor.toLowerCase();
  
  // Catppuccin theme color mappings
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
    // ... additional mappings
  };
  
  return colorNames[hex] || "";
}
```

### 4. Window Management (`windowrules.nix`)

**Purpose**: Hyprland window rules for proper floating behavior and styling

**Rule Categories**:

*Floating Rules*:
```nix
"float, class:^(org\\.qt-project\\.qml)$, title:^(Hyprland Keybinds)$"
"float, class:^(org\\.qt-project\\.qml)$, title:^(Emacs Leader Keybinds)$"  
"float, class:^(org\\.qt-project\\.qml)$, title:^(Kitty Configuration)$"
"float, class:^(org\\.qt-project\\.qml)$, title:^(WezTerm Configuration)$"
"float, class:^(org\\.qt-project\\.qml)$, title:^(Yazi Configuration)$"
```

*Centering Rules*:
```nix
"center, class:^(org\\.qt-project\\.qml)$, title:^(Hyprland Keybinds)$"
"center, class:^(org\\.qt-project\\.qml)$, title:^(Emacs Leader Keybinds)$"
# ... additional centering rules for each mode
```

*Styling Rules (windowrulev2)*:
```nix
"noborder, class:^(org\\.qt-project\\.qml)$, title:^(Hyprland Keybinds)$"
"noshadow, class:^(org\\.qt-project\\.qml)$, title:^(Hyprland Keybinds)$" 
"rounding 12, class:^(org\\.qt-project\\.qml)$, title:^(Hyprland Keybinds)$"
"opacity 0.95 0.95, class:^(org\\.qt-project\\.qml)$, title:^(Hyprland Keybinds)$"
# ... replicated for each mode
```

## Data Flow Architecture

### 1. Initialization Flow
```
User Command → Argument Parsing → Mode Validation → 
Temporary Directory Creation → Data Generation → 
QML Interface Creation → QuickShell Launch
```

### 2. Data Generation Flow
```
keybinds-parser MODE [SUBMODE] →
AWK Processing → Configuration File Parsing →
JSON Structure Generation → File Output
```

### 3. UI Data Flow
```
QML Component.onCompleted → loadKeybindsData() →
XMLHttpRequest → JSON.parse() → Model Population →
Category Extraction → UI Rendering
```

### 4. Submode Switching Flow  
```
Category Button Click → loadKeybindsDataWithSubMode() →
Dynamic File Path → XMLHttpRequest → Data Normalization →
Model Update → UI Refresh
```

## JSON Data Structures

### Standard Keybind Object
```json
{
  "keybind": "Super + t",
  "description": "Run: kitty",  
  "category": "terminal"
}
```

### Summary/Colors Object (Normalized)
```json
{
  "setting": "font_size",
  "value": "12",
  "category": "font"
}
```

### Color Object with Hex Value
```json
{
  "setting": "foreground",
  "value": "#cdd6f4",
  "category": "basic"
}
```

## Category System

### Core Categories (Hyprland)
- `terminal` - Terminal applications
- `editor` - Text editors and IDEs
- `launcher` - Application launchers  
- `browser` - Web browsers
- `screenshot` - Screenshot tools
- `wallpaper` - Wallpaper management
- `media` - Volume, brightness, audio controls
- `window` - Window management actions
- `workspace` - Workspace operations
- `hyprland` - Built-in Hyprland functions
- `app` - Generic applications

### Terminal-Specific Categories

**Kitty/WezTerm**:
- `font` - Font configuration
- `window` - Window appearance
- `colors` - Color scheme
- `cursor` - Cursor settings
- `scrolling` - Scroll behavior
- `tabs` - Tab management
- `panes` - Pane operations
- `clipboard` - Copy/paste operations

**Yazi**:
- `manager` - File manager operations
- `completion` - Auto-completion
- `dialogs` - Confirmation dialogs
- `input` - Text input modes
- `file-management` - File operations
- `theme` - Visual theming
- `keymaps` - Keymap configuration

## Error Handling

### Shell Script Error Handling
```bash
set -euo pipefail  # Strict error handling

# Validation with informative errors
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: Config file not found at $CONFIG_FILE" >&2
  exit 1
fi

# Mode validation  
if [[ "$MODE" != "hyprland" && "$MODE" != "emacs" && ... ]]; then
  echo "Error: Invalid mode '$MODE'. Use 'hyprland', 'emacs', 'kitty', 'wezterm', or 'yazi'" >&2
  exit 1
fi
```

### QML Error Handling
```javascript
try {
  const result = JSON.parse(xhr.responseText);
  win.keybindsData = result;
  win.dataLoaded = true;
  win.populateModel(win.keybindsData);
} catch (e) {
  console.error("Failed to parse keybinds JSON:", e);
  win.keybindsData = [];
  win.dataLoaded = true;  
  win.populateModel([]);
}
```

### AWK Error Prevention
```awk
# Safe array access
if (length(parts) >= 3) {
  # Process parts safely
}

# JSON escaping
gsub(/\\/, "\\\\\\\\", keybind)
gsub(/"/, "\\\\\\"", keybind)

# Field validation
if (keybind != "" && description != "") {
  # Output JSON
}
```

## Performance Considerations

### Timing and Profiling
```bash
# Performance monitoring
now_ms() { date +%s%3N; }

if [ -n "${QS_PERF:-}" ]; then
  t1=$(now_ms)
  # Operation
  t2=$(now_ms) 
  echo "[perf] json_ms=$((t2 - t1))" >&2
fi
```

### Optimization Strategies

**Data Generation**:
- Single-pass AWK processing
- Minimal temporary file creation
- Efficient JSON structure generation
- Pre-generated submode files for faster switching

**UI Performance**:
- Lazy data loading with XMLHttpRequest
- Client-side filtering for responsive search
- Model population with progress tracking
- Minimal DOM manipulation in QML

**Memory Management**:
- Temporary directory cleanup
- Efficient JavaScript object handling
- Limited data retention in memory

## Maintenance Guide

### Adding New Modes

1. **Update Mode Validation**:
```bash
# In qs-keybinds.nix
if [[ "$MODE" != "hyprland" && "$MODE" != "emacs" && ... && "$MODE" != "newmode" ]]; then
```

2. **Add Parser Logic**:
```bash
# In keybinds-parser.nix  
newmode)
  CONFIG_FILE="$HOME/.config/newmode/config"
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config not found" >&2
    exit 1
  fi
  
  case "$SUBMODE" in
    summary) # ... ;;
    colors) # ... ;;  
    *) # keybinds ... ;;
  esac
  ;;
```

3. **Update UI Logic**:
```javascript
// Add to getCategories() function
if (selectedMode === "kitty" || selectedMode === "wezterm" || 
    selectedMode === "yazi" || selectedMode === "newmode") {
  return ["all", "summary", "keybinds", "colors"];
}

// Add to button click handler
if ((win.selectedMode === "kitty" || win.selectedMode === "wezterm" || 
     win.selectedMode === "yazi" || win.selectedMode === "newmode") && 
    modelData !== "all") {
```

4. **Add Window Rules**:
```nix
# In windowrules.nix
"float, class:^(org\\.qt-project\\.qml)$, title:^(NewMode Configuration)$"
"center, class:^(org\\.qt-project\\.qml)$, title:^(NewMode Configuration)$"
# ... styling rules
```

5. **Add UI Button**:
```qml
Button {
  text: "NewMode"  
  width: 120
  height: 36
  // ... styling and click handler
}
```

### Debugging Procedures

**Parser Debugging**:
```bash
# Test parser directly
keybinds-parser newmode summary | jq '.'
keybinds-parser newmode keybinds | jq 'length'
keybinds-parser newmode colors | jq '.[0:3]'

# Shell-only mode for testing
QS_SHELL_ONLY=1 qs-keybinds -m newmode
```

**Performance Debugging**:
```bash
# Enable performance output
QS_PERF=1 qs-keybinds -m newmode

# Auto-quit for testing
QS_AUTO_QUIT=1 qs-keybinds -m newmode
```

**UI Debugging**:
- Check browser console for JavaScript errors
- Verify JSON structure with `jq`
- Test XMLHttpRequest file access
- Validate QML syntax with QuickShell

### Common Issues and Solutions

**Issue**: Empty submode data
**Solution**: Check file paths, AWK regex patterns, and JSON escaping

**Issue**: UI not updating on category switch
**Solution**: Verify `loadKeybindsDataWithSubMode()` function and file path construction

**Issue**: Window not floating
**Solution**: Add proper window rules in `windowrules.nix`

**Issue**: Search not working
**Solution**: Check `filterKeybinds()` function and ensure proper data structure

## Build and Deployment

### Nix Build Process
```bash
# Development build
sudo nixos-rebuild switch --flake .

# Check script availability  
which qs-keybinds
which keybinds-parser

# Test modes
qs-keybinds -m hyprland
qs-keybinds -m kitty
```

### Dependencies
- `pkgs.gawk` - AWK processing
- `pkgs.jq` - JSON processing (parser testing)
- `pkgs.coreutils` - Date, mktemp utilities
- QuickShell runtime - QML interface
- Qt 6.x - UI framework

### Configuration Files
The application reads from standard configuration locations:
- `~/.config/hypr/hyprland.conf`
- `~/.config/kitty/kitty.conf`  
- `~/.config/wezterm/wezterm.lua`
- `~/.config/yazi/keymap.toml`
- `~/.config/yazi/theme.toml`

## Security Considerations

### Input Validation
- Mode parameter validation against allowed values
- File path validation for configuration files
- JSON escaping to prevent injection

### File Access
- Read-only access to configuration files
- Temporary directory with proper permissions
- No external network access required

### Execution Context
- Runs in user context, no privilege escalation
- Sandboxed QML execution environment
- No arbitrary code execution from configuration files

## Future Enhancements

### Potential Improvements
1. **Configuration Hot-Reload**: Watch config files for changes
2. **Export Functionality**: Export filtered results to various formats
3. **Custom Categories**: User-defined category mappings
4. **Fuzzy Search**: Enhanced search with fuzzy matching
5. **Themes**: Customizable UI themes and color schemes
6. **Plugin System**: Extensible parser architecture
7. **Configuration Validation**: Syntax checking for config files
8. **Backup/Restore**: Configuration backup and restoration tools

### Architecture Scalability
- Modular parser design allows easy extension
- QML component architecture supports additional UI features  
- JSON data format provides flexible data exchange
- Nix build system enables reproducible deployments

## Conclusion

The `qs-keybinds` application provides a comprehensive, extensible platform for configuration management and keybind visualization. Its modular architecture, robust error handling, and performance optimization make it suitable for both individual use and team deployment scenarios. The detailed documentation and maintenance procedures ensure long-term sustainability and ease of enhancement.
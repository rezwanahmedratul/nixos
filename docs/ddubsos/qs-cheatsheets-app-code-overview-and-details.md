# qs-cheatsheets Application: Technical Documentation

## Overview

The `qs-cheatsheets` application is a comprehensive cheatsheet viewer built with QuickShell (Qt/QML) for displaying and searching markdown documentation from the `~/ddubsos/cheatsheets/` directory. It provides a unified interface for browsing cheatsheets across multiple categories with real-time search capabilities and multi-language support.

## Architecture

### Core Components

```
qs-cheatsheets/
├── modules/home/scripts/
│   ├── qs-cheatsheets.nix          # Main launcher script
│   └── cheatsheets-parser.nix      # Markdown file parser
└── modules/home/hyprland/
    └── windowrules.nix             # Window management rules
```

### Technology Stack
- **Shell**: Bash with `set -euo pipefail` for strict error handling
- **Parser**: Native bash with find/grep for markdown processing and JSON generation
- **UI**: Qt 6.x/QML with QuickShell runtime
- **Build System**: Nix with flake.nix configuration
- **Window Manager**: Hyprland with custom window rules
- **Content Format**: Markdown files with multilingual support

## File Structure and Code Layout

### 1. Main Launcher (`qs-cheatsheets.nix`)

**Purpose**: Primary entry point that handles argument parsing, markdown file discovery, and QML interface creation.

**Key Functions**:

#### Command Line Interface
```bash
qs-cheatsheets [options]

Options:
  -c CATEGORY   Category to display (emacs|hyprland|kitty|wezterm|yazi|nixos) (default: emacs)
  -l LANGUAGE   Language (en|es) (default: en)
  -h            Show help
  
Special flags:
  --shell-only    Skip QML interface, only generate JSON data
  
Environment Variables:
  QS_PERF=1           Enable performance timing output
  QS_AUTO_QUIT=1      Auto-quit after model population (testing)
  QS_SHELL_ONLY=1     Skip QML interface
  CHEATSHEETS_CATEGORY=category  Set default category
  CHEATSHEETS_LANGUAGE=lang      Set default language
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
while getopts ":c:l:h" opt; do
  case "$opt" in
    c) CATEGORY="$OPTARG" ;;
    l) LANGUAGE="$OPTARG" ;;
    h) usage; exit 0 ;;
    :) echo "Missing argument for -$OPTARG" >&2; exit 2 ;;
    \\?) echo "Unknown option -$OPTARG" >&2; usage; exit 2 ;;
  esac
done
```

**Category Validation**:
```bash
# Validate category (dynamically check if directory exists or is "root")
if [[ "$CATEGORY" != "root" && ! -d "$HOME/ddubsos/cheatsheets/$CATEGORY" ]]; then
  echo "Error: Category directory '$CATEGORY' not found in cheatsheets/" >&2
  echo "Available categories:" >&2
  echo "  root" >&2
  ls -1 "$HOME/ddubsos/cheatsheets/" | grep -E '^[a-z]' | head -10 >&2
  exit 1
fi
```

**Data Generation Pipeline**:
1. Create temporary directory with `mktemp -d`
2. Generate files JSON for current category and language using cheatsheets-parser
3. Generate categories JSON listing all available categories
4. Pre-generate files JSON for all categories and languages for switching:
   - Root directory files for both languages
   - All category directories for both languages
5. Create QML interface file with embedded configuration
6. Launch QuickShell with generated QML

**Performance Monitoring**:
```bash
now_ms() { date +%s%3N; }
if [ -n "${QS_PERF:-}" ]; then 
  t1=$(now_ms)
  # ... operation
  t2=$(now_ms)
  echo "[perf] json_ms=$((t2 - t1))" >&2
fi
```

### 2. Markdown File Parser (`cheatsheets-parser.nix`)

**Purpose**: Multi-format markdown parser that discovers and processes cheatsheet files from the filesystem with metadata extraction.

#### Parser Architecture

**Entry Point**:
```bash
cheatsheets-parser MODE [CATEGORY] [LANGUAGE]

MODE: files|content|categories
CATEGORY: emacs|hyprland|kitty|wezterm|yazi|nix|root|etc.
LANGUAGE: en|es
```

#### Mode-Specific Processing

##### Files Mode Parser
**Purpose**: Generate JSON list of available files for a category
**File Discovery**: Uses `find` with `-print0` and `sort -z` for safe filename handling

**Root Category Processing**:
```bash
if [[ "$CATEGORY" == "root" ]]; then
  # Find markdown files directly in cheatsheets root directory
  if [[ -d "$CHEATSHEETS_DIR" ]]; then
    first=true
    
    while IFS= read -r -d "" filepath; do
      file_lang=$(get_language "$filepath")
      
      # Filter by requested language
      if [[ "$file_lang" == "$LANGUAGE" ]]; then
        clean_name=$(get_clean_filename "$filepath")
        title=$(get_title_from_file "$filepath")
        
        # JSON output generation
      fi
    done < <(find "$CHEATSHEETS_DIR" -maxdepth 1 -name "*.md" -print0 | sort -z)
  fi
fi
```

**Category Directory Processing**:
```bash
elif [[ -d "$CHEATSHEETS_DIR/$CATEGORY" ]]; then
  first=true
  
  while IFS= read -r -d "" filepath; do
    file_lang=$(get_language "$filepath")
    
    # Filter by requested language
    if [[ "$file_lang" == "$LANGUAGE" ]]; then
      clean_name=$(get_clean_filename "$filepath")
      title=$(get_title_from_file "$filepath")
      
      # JSON structure generation
      cat <<JSON_ENTRY
{
  "filename": "$(basename "$filepath")",
  "clean_name": "$clean_name",
  "title": "$title",
  "category": "$CATEGORY",
  "language": "$file_lang",
  "path": "$filepath"
}
JSON_ENTRY
    fi
  done < <(find "$CHEATSHEETS_DIR/$CATEGORY" -name "*.md" -print0 | sort -z)
fi
```

##### Content Mode Parser
**Purpose**: Extract file content with metadata for API access
**Content Processing**: Raw file reading with JSON encoding

```bash
if [[ -n "$FILENAME" ]]; then
  # Single file content
  if [[ -f "$CHEATSHEETS_DIR/$CATEGORY/$FILENAME" ]]; then
    cat "$CHEATSHEETS_DIR/$CATEGORY/$FILENAME"
  fi
else
  # All files metadata with content
  while IFS= read -r -d "" filepath; do
    if [[ "$file_lang" == "$LANGUAGE" ]]; then
      content=$(cat "$filepath" | jq -R -s .)
      
      cat <<JSON_ENTRY
{
  "filename": "$(basename "$filepath")",
  "clean_name": "$clean_name", 
  "title": "$title",
  "category": "$CATEGORY",
  "language": "$file_lang",
  "path": "$filepath",
  "content": $content
}
JSON_ENTRY
    fi
  done < <(find "$CHEATSHEETS_DIR/$CATEGORY" -name "*.md" -print0 | sort -z)
fi
```

##### Categories Mode Parser
**Purpose**: List all available categories dynamically
**Discovery Logic**: Filesystem-based category detection with root support

```bash
# Always include "root" category for files in cheatsheets/ root directory
if [[ -d "$CHEATSHEETS_DIR" ]] && [[ $(find "$CHEATSHEETS_DIR" -maxdepth 1 -name "*.md" | wc -l) -gt 0 ]]; then
  echo "    \"root\""
  first=false
fi

if [[ -d "$CHEATSHEETS_DIR" ]]; then
  for dir in "$CHEATSHEETS_DIR"/*; do
    if [[ -d "$dir" ]]; then
      category=$(basename "$dir")
      echo "    \"$category\""
    fi
  done
fi
```

#### Helper Functions

**Filename Cleaning**:
```bash
get_clean_filename() {
  local filepath="$1"
  local basename=$(basename "$filepath")
  
  # Remove category prefix (e.g., "emacs.")
  basename=$(echo "$basename" | sed 's/^[^.]*\.//')
  
  # Remove language suffix (.es.md or .md)
  basename=$(echo "$basename" | sed 's/\.es\.md$//' | sed 's/\.md$//')
  
  # Remove common suffixes
  basename=$(echo "$basename" | sed 's/\.cheatsheet$//' | sed 's/\.top10$//')
  
  echo "$basename"
}
```

**Language Detection**:
```bash
get_language() {
  local filepath="$1"
  if [[ "$filepath" == *.es.md ]]; then
    echo "es"
  else
    echo "en"
  fi
}
```

**Title Extraction**:
```bash
get_title_from_file() {
  local filepath="$1"
  
  if [[ -f "$filepath" ]]; then
    # Look for the first H1 header in the file
    local title=$(grep -m1 "^# " "$filepath" 2>/dev/null | sed 's/^# //' || echo "")
    if [[ -n "$title" ]]; then
      echo "$title"
    else
      # Fallback to clean filename
      get_clean_filename "$filepath"
    fi
  fi
}
```

### 3. QML User Interface

**Architecture**: Single-file QML application with embedded JavaScript logic for cheatsheet browsing

#### Core Properties
```javascript
property string selectedCategory: "$CATEGORY"
property string selectedLanguage: "$LANGUAGE"
property string selectedFile: ""
property string fileContent: ""
property string displayedContent: ""
property string searchQuery: ""

// Search state
property int searchCount: 0
property int currentMatchIndex: 0
property var matchPositions: [] // array of [start,end] in plain text indices

// Data
property var cheatsheetFiles: []
property bool filesLoaded: false
property var availableCategories: []
```

#### Key Functions

**File Data Loading**:
```javascript
function loadCheatsheetFiles() {
  console.log("Loading files for:", selectedCategory, selectedLanguage);
  
  var fileName = "files_" + selectedCategory + "_" + selectedLanguage + ".json";
  var filePath = tmpDir + "/" + fileName;
  
  const xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function() {
    if (xhr.readyState === XMLHttpRequest.DONE) {
      if (xhr.status === 200 || xhr.status === 0) {
        try {
          const result = JSON.parse(xhr.responseText);
          win.cheatsheetFiles = result;
          win.filesLoaded = true;
          
          // Populate the ListModel
          filesModel.clear();
          for (var i = 0; i < result.length; i++) {
            var file = result[i];
            filesModel.append({
              filename: file.filename || "",
              clean_name: file.clean_name || "",
              title: file.title || "",
              category: file.category || "",
              language: file.language || "",
              path: file.path || ""
            });
          }
        } catch (e) {
          console.error("Failed to parse files JSON:", e);
        }
      }
    }
  };
  xhr.open("GET", "file://" + filePath);
  xhr.send();
}
```

**File Content Loading**:
```javascript
function loadFileContent(filename) {
  console.log("Loading content for:", filename);
  
  // Handle root directory files
  var filePath;
  if (selectedCategory === "root") {
    filePath = "/home/dwilliams/ddubsos/cheatsheets/" + filename;
  } else {
    filePath = "/home/dwilliams/ddubsos/cheatsheets/" + selectedCategory + "/" + filename;
  }
  
  const xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function() {
    if (xhr.readyState === XMLHttpRequest.DONE) {
      if (xhr.status === 200 || xhr.status === 0) {
        win.fileContent = xhr.responseText;
        win.selectedFile = filename;
        win.updateSearch(); // recompute matches and content
      } else {
        win.fileContent = "Error loading file: " + filename;
      }
    }
  };
  xhr.open("GET", "file://" + filePath);
  xhr.send();
}
```

**Search and Highlighting**:
```javascript
function updateSearch() {
  matchPositions = [];
  searchCount = 0;
  currentMatchIndex = 0;

  if (!fileContent || !searchQuery || searchQuery.trim() === "") {
    rebuildDisplayedContent();
    return;
  }
  
  var needle = searchQuery.toLowerCase();
  var hay = fileContent.toLowerCase();
  var idx = 0;
  
  while (true) {
    var pos = hay.indexOf(needle, idx);
    if (pos === -1) break;
    matchPositions.push([pos, pos + needle.length]);
    idx = pos + needle.length;
  }
  
  searchCount = matchPositions.length;
  if (searchCount === 0) {
    rebuildDisplayedContent();
    return;
  }
  currentMatchIndex = 0;
  rebuildDisplayedContent();
}

function rebuildDisplayedContent() {
  if (!fileContent || fileContent.length === 0) {
    displayedContent = "";
    return;
  }
  
  if (searchCount === 0 || matchPositions.length === 0) {
    displayedContent = "<pre style=\"white-space:pre-wrap;\">" + escapeHtml(fileContent) + "</pre>";
    return;
  }
  
  // Build highlighted HTML with all matches; current one emphasized
  var html = "<pre style=\"white-space:pre-wrap;\">";
  var last = 0;
  for (var i = 0; i < matchPositions.length; i++) {
    var start = matchPositions[i][0];
    var end = matchPositions[i][1];
    html += escapeHtml(fileContent.slice(last, start));
    var seg = escapeHtml(fileContent.slice(start, end));
    
    if (i === currentMatchIndex) {
      html += "<span style=\"background:#ffee58;color:#000;padding:1px 0;border-radius:2px;\">" + seg + "</span>";
    } else {
      html += "<span style=\"background:#665500;color:#fff;padding:1px 0;border-radius:2px;\">" + seg + "</span>";
    }
    last = end;
  }
  html += escapeHtml(fileContent.slice(last));
  html += "</pre>";
  displayedContent = html;
}
```

**Category and Language Switching**:
```javascript
function switchCategory(newCategory) {
  selectedCategory = newCategory;
  selectedFile = "";
  fileContent = "";
  loadCheatsheetFiles();
}

function switchLanguage(newLanguage) {
  selectedLanguage = newLanguage;
  selectedFile = "";
  fileContent = "";
  loadCheatsheetFiles();
}
```

**HTML Escaping for Safe Display**:
```javascript
function escapeHtml(s) {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/\"/g, "&quot;")
    .replace(/'/g, "&#39;");
}
```

### 4. Window Management (`windowrules.nix`)

**Purpose**: Hyprland window rules for proper floating behavior and styling

**Rule Categories**:

*Floating Rules*:
```nix
"float, class:^(org\\.qt-project\\.qml)$, title:^(Cheatsheets Viewer)$"
"center, class:^(org\\.qt-project\\.qml)$, title:^(Cheatsheets Viewer)$"
```

*Styling Rules (windowrulev2)*:
```nix
"noborder, class:^(org\\.qt-project\\.qml)$, title:^(Cheatsheets Viewer)$"
"noshadow, class:^(org\\.qt-project\\.qml)$, title:^(Cheatsheets Viewer)$"
"rounding 12, class:^(org\\.qt-project\\.qml)$, title:^(Cheatsheets Viewer)$"
"opacity 0.95 0.95, class:^(org\\.qt-project\\.qml)$, title:^(Cheatsheets Viewer)$"
```

## Data Flow Architecture

### 1. Initialization Flow
```
User Command → Argument Parsing → Category/Language Validation → 
Temporary Directory Creation → Data Generation → 
QML Interface Creation → QuickShell Launch
```

### 2. Data Generation Flow
```
cheatsheets-parser files CATEGORY LANGUAGE →
Filesystem Discovery → Markdown File Processing →
JSON Structure Generation → File Output
```

### 3. UI Data Flow
```
QML Component.onCompleted → loadCheatsheetFiles() →
XMLHttpRequest → JSON.parse() → Model Population →
Category Extraction → UI Rendering
```

### 4. Content Loading Flow
```
File Selection → loadFileContent() →
Direct File Access → Raw Content Load →
Search Processing → HTML Generation → Display Update
```

## JSON Data Structures

### File Object
```json
{
  "filename": "emacs.getting-started.top10.md",
  "clean_name": "getting-started.top10",
  "title": "Emacs Getting Started: Top 10 Essential Commands",
  "category": "emacs",
  "language": "en",
  "path": "/home/dwilliams/ddubsos/cheatsheets/emacs/emacs.getting-started.top10.md"
}
```

### Categories Array
```json
[
  "root",
  "emacs", 
  "hyprland",
  "kitty",
  "wezterm",
  "yazi",
  "nixos"
]
```

## Category System

### Available Categories
Based on filesystem structure in `~/ddubsos/cheatsheets/`:

- `root` - Files in the cheatsheets root directory
- `emacs` - Emacs editor cheatsheets
- `hyprland` - Hyprland window manager documentation
- `kitty` - Kitty terminal emulator
- `wezterm` - WezTerm terminal emulator
- `yazi` - Yazi file manager
- `nixos` - NixOS system configuration
- `ghostty` - Ghostty terminal (if directory exists)
- `alacritty` - Alacritty terminal (if directory exists)

### Language Support
- `en` - English (default)
- `es` - Spanish (files ending in .es.md)

### File Naming Convention
- English: `category.topic.type.md` (e.g., `emacs.magit.cheatsheet.md`)
- Spanish: `category.topic.type.es.md` (e.g., `emacs.magit.cheatsheet.es.md`)

## Error Handling

### Shell Script Error Handling
```bash
set -euo pipefail  # Strict error handling

# Category validation
if [[ "$CATEGORY" != "root" && ! -d "$HOME/ddubsos/cheatsheets/$CATEGORY" ]]; then
  echo "Error: Category directory '$CATEGORY' not found in cheatsheets/" >&2
  echo "Available categories:" >&2
  ls -1 "$HOME/ddubsos/cheatsheets/" | grep -E '^[a-z]' | head -10 >&2
  exit 1
fi

# Language validation  
if [[ "$LANGUAGE" != "en" && "$LANGUAGE" != "es" ]]; then
  echo "Error: Invalid language '$LANGUAGE'. Use 'en' or 'es'" >&2
  exit 1
fi
```

### QML Error Handling
```javascript
try {
  const result = JSON.parse(xhr.responseText);
  win.cheatsheetFiles = result;
  win.filesLoaded = true;
  win.populateModel(win.cheatsheetFiles);
} catch (e) {
  console.error("Failed to parse files JSON:", e);
  console.log("Response text:", xhr.responseText);
  win.cheatsheetFiles = [];
  win.filesLoaded = true;
  filesModel.clear();
}
```

### File Access Error Handling
```javascript
xhr.onreadystatechange = function() {
  if (xhr.readyState === XMLHttpRequest.DONE) {
    if (xhr.status === 200 || xhr.status === 0) {
      win.fileContent = xhr.responseText;
      win.selectedFile = filename;
      win.updateSearch();
    } else {
      win.fileContent = "Error loading file: " + filename;
      win.displayedContent = "Error loading file: " + filename;
      win.matchPositions = [];
      win.searchCount = 0;
      win.currentMatchIndex = 0;
    }
  }
};
```

## Performance Considerations

### Timing and Profiling
```bash
# Performance monitoring
now_ms() { date +%s%3N; }

if [ -n "${QS_PERF:-}" ]; then
  t1=$(now_ms)
  # JSON generation operation
  t2=$(now_ms) 
  echo "[perf] json_ms=$((t2 - t1))" >&2
fi
```

### Optimization Strategies

**Data Generation**:
- Single-pass filesystem traversal with find
- Efficient JSON generation with minimal processing
- Pre-generated category/language combinations
- Safe filename handling with null-terminated strings

**UI Performance**:
- Lazy file content loading via XMLHttpRequest
- Client-side search with real-time highlighting
- Efficient model population with progress tracking
- Minimal DOM manipulation in QML

**Memory Management**:
- Temporary directory cleanup
- Efficient JavaScript string handling
- Limited content retention in memory
- Smart cache invalidation on category switch

## Maintenance Guide

### Adding New Categories

1. **Create Directory Structure**:
```bash
mkdir -p ~/ddubsos/cheatsheets/newcategory
```

2. **Add Markdown Files**:
```bash
# English version
touch ~/ddubsos/cheatsheets/newcategory/newcategory.topic.cheatsheet.md

# Spanish version  
touch ~/ddubsos/cheatsheets/newcategory/newcategory.topic.cheatsheet.es.md
```

3. **Update Default Categories** (if needed):
```bash
# In qs-cheatsheets.nix, update usage text and validation
# Categories are automatically discovered, no code changes needed
```

### Adding New Languages

1. **Update Language Validation**:
```bash
# In qs-cheatsheets.nix
if [[ "$LANGUAGE" != "en" && "$LANGUAGE" != "es" && "$LANGUAGE" != "newlang" ]]; then
```

2. **Update File Detection**:
```bash
# In cheatsheets-parser.nix
get_language() {
  local filepath="$1"
  if [[ "$filepath" == *.es.md ]]; then
    echo "es"
  elif [[ "$filepath" == *.newlang.md ]]; then
    echo "newlang"
  else
    echo "en"
  fi
}
```

3. **Add UI Language Button**:
```qml
Button {
  text: "NEWLANG"
  width: 40
  height: 28
  // ... styling and click handler
}
```

### Debugging Procedures

**Parser Debugging**:
```bash
# Test parser directly
cheatsheets-parser files emacs en | jq '.'
cheatsheets-parser categories | jq '.'
cheatsheets-parser content emacs en filename.md

# Shell-only mode for testing
QS_SHELL_ONLY=1 qs-cheatsheets -c emacs -l en
```

**Performance Debugging**:
```bash
# Enable performance output
QS_PERF=1 qs-cheatsheets -c emacs

# Auto-quit for testing
QS_AUTO_QUIT=1 qs-cheatsheets -c emacs
```

**UI Debugging**:
- Check browser console for JavaScript errors
- Verify JSON structure with `jq`
- Test XMLHttpRequest file access
- Validate QML syntax with QuickShell

### Common Issues and Solutions

**Issue**: Empty category data
**Solution**: Check directory exists and contains .md files, verify find command patterns

**Issue**: UI not updating on language switch  
**Solution**: Verify `loadCheatsheetFiles()` function and file path construction for language variants

**Issue**: Search highlighting broken
**Solution**: Check `updateSearch()` function and HTML escaping in `rebuildDisplayedContent()`

**Issue**: File content not loading
**Solution**: Verify file paths, check XMLHttpRequest file:// protocol access, validate markdown file existence

## Build and Deployment

### Nix Build Process
```bash
# Development build
sudo nixos-rebuild switch --flake .

# Check script availability  
which qs-cheatsheets
which cheatsheets-parser

# Test categories
qs-cheatsheets -c emacs
qs-cheatsheets -c hyprland -l es
```

### Dependencies
- `pkgs.findutils` - File discovery
- `pkgs.gnugrep` - Text processing
- `pkgs.jq` - JSON processing (for content mode)
- `pkgs.coreutils` - Date, mktemp utilities
- QuickShell runtime - QML interface
- Qt 6.x - UI framework

### Content Directory Structure
The application reads from `~/ddubsos/cheatsheets/`:
```
cheatsheets/
├── README.md                           # Root level documentation
├── emacs/
│   ├── emacs.getting-started.top10.md
│   ├── emacs.getting-started.top10.es.md  
│   ├── emacs.magit.cheatsheet.md
│   └── emacs.magit.cheatsheet.es.md
├── hyprland/
│   ├── hyprland.keybinds.cheatsheet.md
│   └── hyprland.theming.guide.es.md
└── [other categories...]
```

## Security Considerations

### Input Validation
- Category parameter validation against filesystem directories
- Language parameter validation against allowed values
- File path validation and sanitization
- Safe filename handling with null-terminated strings

### File Access
- Read-only access to cheatsheet files
- Restricted to cheatsheets directory tree
- No arbitrary file system access
- Temporary directory with proper permissions

### Execution Context
- Runs in user context, no privilege escalation
- Sandboxed QML execution environment
- No external network access required
- Direct file system access only to designated directories

## Future Enhancements

### Potential Improvements
1. **Markdown Rendering**: Enhanced markdown parsing with syntax highlighting
2. **Export Functionality**: Export cheatsheets to PDF, HTML, or other formats
3. **Custom Categories**: User-defined category organization
4. **Advanced Search**: Regular expressions, tag-based filtering
5. **Themes**: Customizable UI themes and typography
6. **Bookmarking**: Favorite cheatsheets and quick access
7. **Auto-Update**: Watch filesystem for new cheatsheets
8. **Collaboration**: Share and sync cheatsheets across devices

### Architecture Scalability
- Modular parser design allows easy format extension
- QML component architecture supports additional UI features
- JSON data format provides flexible data exchange
- Nix build system enables reproducible deployments
- Filesystem-based content allows easy maintenance

## Conclusion

The `qs-cheatsheets` application provides a robust, extensible platform for markdown-based documentation viewing with real-time search and multilingual support. Its simple filesystem-based architecture, efficient search capabilities, and clean UI make it ideal for managing technical documentation and reference materials. The detailed documentation and maintenance procedures ensure long-term sustainability and ease of enhancement.

---

## 2025-09 Rendering and Search Overhaul

This release significantly improves Markdown fidelity and search UX.

Summary of changes:
- Markdown is pre-converted to HTML via pandoc for accurate rendering of code blocks, tables, lists, and nested elements.
- The viewer switches from MarkdownText to RichText, rendering the generated HTML.
- Inline highlight spans are removed. Instead, a Matches side panel provides clickable snippets and approximate jump-to navigation.
- New properties and models are introduced to support the new UX.

### Rendering pipeline (Markdown → HTML → RichText)

- At startup, the launcher pre-generates JSON manifests for files and categories (unchanged), then converts discovered markdown files to HTML under a QML session temp directory:
  - Location: $TMPDIR/html/<category>/<language>/<file>.html
  - Tool: pandoc (GitHub-Flavored Markdown), with a sed fallback to escaped <pre> on conversion errors.
- QML now loads both the raw markdown (for searching) and the pre-converted HTML (for display). The display prioritizes HTML; if HTML is unavailable, it falls back to an escaped <pre> of the markdown.

Key Bash helper (added to the launcher):
- Converts all referenced markdown from the generated files_*.json manifests.
- Note the ''${...} escaping is required inside Nix strings to prevent Nix interpolation.

```bash
convert_markdown_sets() {
  # Iterate all generated files_*.json manifests
  for json in "$tmpdir"/files_*.json; do
    [ -f "$json" ] || continue
    name=$(basename "$json")
    # files_<category>_<lang>.json
    category="''${name#files_}"
    category="''${category%_*}"
    language="''${name##*_}"
    language="''${language%.json}"
    outdir="$tmpdir/html/$category/$language"
    ${pkgs.coreutils}/bin/mkdir -p "$outdir"
    # Extract file paths from manifest
    while IFS= read -r src; do
      [ -n "$src" ] || continue
      base="$(basename "$src")"
      base_noext="''${base%.*}"
      out="$outdir/''${base_noext}.html"
      # Convert with pandoc (GFM). Fallback to escaped <pre> if conversion fails.
      if ! ${pkgs.pandoc}/bin/pandoc -f gfm -t html5 --wrap=none "$src" -o "$out" 2>/dev/null; then
        esc=$(<"$src" ${pkgs.gnused}/bin/sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')
        printf '<pre style="white-space:pre-wrap;">%s</pre>' "$esc" > "$out"
      fi
    done < <(${pkgs.jq}/bin/jq -r '.[] | .path // empty' "$json" 2>/dev/null)
  done
}
```

Dependencies added:
- pandoc (markdown → HTML)
- jq (reads manifest JSON)
- sed (fallback escaping)

### QML model and properties

New/changed top-level properties:
- fileContent: string (raw markdown, used for searching)
- htmlContent: string (HTML produced by pandoc)
- displayedContent: string (what we actually render)
- matchesModel: ListModel of matches with fields: idx, start, snippet

Display rebuild prefers HTML:
```js
function rebuildDisplayedContent() {
  if (!fileContent || fileContent.length === 0) {
    displayedContent = "";
    return;
  }
  // Prefer pre-converted HTML; fallback to escaped pre
  if (htmlContent && htmlContent.length > 0) {
    displayedContent = htmlContent;
  } else {
    displayedContent = "<pre style=\"white-space:pre-wrap;\">" + escapeHtml(fileContent) + "</pre>";
  }
}
```

### Viewer component: RichText

The content display switched from Text (MarkdownText) to TextEdit (RichText) to render HTML accurately:
```qml
ScrollView {
  id: contentScroll
  TextEdit {
    id: contentDisplay
    text: win.displayedContent
    textFormat: TextEdit.RichText
    readOnly: true
    selectByMouse: true
    wrapMode: TextEdit.Wrap
  }
}
```

### Search UX: Matches side panel and approximate jump

- updateSearch() now computes matchPositions over the raw markdown (case-insensitive) and builds matchesModel with context snippets (~80 chars around each hit, newlines collapsed to spaces).
- A Matches panel on the right lists the hits; clicking one jumps approximately to that position by setting contentY proportionally to start/fileContent.length.
- Prev/Next actions now call jumpToMatch(index) rather than rebuilding inline highlights.

Core functions:
```js
function updateSearch() {
  matchPositions = [];
  searchCount = 0;
  currentMatchIndex = 0;
  matchesModel.clear();
  if (!fileContent || !searchQuery || searchQuery.trim() === "") { rebuildDisplayedContent(); return; }
  var needle = String(searchQuery).toLowerCase();
  var hay = String(fileContent).toLowerCase();
  var idx = 0; let pos;
  while ((pos = hay.indexOf(needle, idx)) !== -1) {
    matchPositions.push([pos, pos + needle.length]);
    idx = pos + needle.length;
  }
  searchCount = matchPositions.length;
  for (var j = 0; j < matchPositions.length; j++) {
    var s = matchPositions[j][0]; var e = matchPositions[j][1];
    var ctxStart = Math.max(0, s - 80); var ctxEnd = Math.min(fileContent.length, e + 80);
    var snippet = fileContent.slice(ctxStart, ctxEnd).replace(/\n/g, " ");
    matchesModel.append({ idx: j, start: s, snippet: snippet });
  }
  currentMatchIndex = (searchCount > 0) ? 0 : 0;
  rebuildDisplayedContent();
}

function scrollToApproximatePosition(pos) {
  var flick = contentScroll && contentScroll.contentItem ? contentScroll.contentItem : null;
  if (!flick || !fileContent || fileContent.length === 0) return;
  var ratio = Math.max(0, Math.min(1, pos / fileContent.length));
  var maxY = Math.max(0, flick.contentHeight - contentScroll.height);
  flick.contentY = ratio * maxY;
}

function jumpToMatch(index) {
  if (searchCount <= 0) return;
  var clamped = Math.max(0, Math.min(searchCount - 1, index));
  currentMatchIndex = clamped;
  var start = matchPositions[currentMatchIndex][0];
  scrollToApproximatePosition(start);
  if (typeof matchesList !== 'undefined' && matchesList) {
    matchesList.positionViewAtIndex(currentMatchIndex, ListView.Center);
  }
}
```

UI additions (Matches panel excerpt):
```qml
Rectangle {
  id: matchesPanel
  visible: win.searchCount > 0 && matchesToggle.checked
  width: 320
  Column {
    Text { text: "Matches (" + win.searchCount + ")" }
    ListView {
      id: matchesList
      model: matchesModel
      delegate: Rectangle {
        property int matchIndex: model.idx || index
        property string snippet: model.snippet || ""
        MouseArea { anchors.fill: parent; onClicked: win.jumpToMatch(matchIndex) }
        Text { text: snippet; textFormat: Text.PlainText; wrapMode: Text.Wrap }
      }
    }
  }
}
```

Trade-offs:
- Approximate jump is based on character index ratio; it is fast and good enough for long documents but may land slightly before/after the exact match. Future work can refine this by mapping headings to anchor offsets or estimating block heights.
- Inline highlight was removed to preserve HTML fidelity; reintroducing inline highlight would require HTML mutation or a WebEngine-based approach.

Troubleshooting:
- If Nix reports a syntax error in the launcher, confirm Bash parameter expansions are escaped as ''${var} inside Nix strings.
- If code blocks look plain, ensure pandoc is available in the environment and that conversion ran (check $TMPDIR/html/... for the HTML file).
- If matches list shows [0/0], verify searchQuery and that fileContent is loaded before htmlContent.

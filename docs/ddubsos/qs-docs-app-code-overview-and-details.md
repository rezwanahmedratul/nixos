# qs-docs Application: Technical Documentation

## Overview

The `qs-docs` application is a comprehensive documentation viewer built with QuickShell (Qt/QML) for displaying and searching markdown documentation from the `~/ddubsos/docs/` directory. It provides a unified interface for browsing documentation across multiple categories with real-time search capabilities and multi-language support, specifically designed for technical documentation and project notes.

## Architecture

### Core Components

```
qs-docs/
├── modules/home/scripts/
│   ├── qs-docs.nix          # Main launcher script
│   └── docs-parser.nix      # Markdown file parser
└── modules/home/hyprland/
    └── windowrules.nix      # Window management rules
```

### Technology Stack
- **Shell**: Bash with `set -euo pipefail` for strict error handling
- **Parser**: Native bash with find/grep for markdown processing and JSON generation
- **UI**: Qt 6.x/QML with QuickShell runtime
- **Build System**: Nix with flake.nix configuration
- **Window Manager**: Hyprland with custom window rules
- **Content Format**: Markdown files with multilingual support

## File Structure and Code Layout

### 1. Main Launcher (`qs-docs.nix`)

**Purpose**: Primary entry point that handles argument parsing, markdown file discovery, and QML interface creation for documentation browsing.

**Key Functions**:

#### Command Line Interface
```bash
qs-docs [options]

Options:
  -c CATEGORY   Category to display (AI|ddubsos) (default: AI)
  -l LANGUAGE   Language (en|es) (default: en)
  -h            Show help
  
Special flags:
  --shell-only    Skip QML interface, only generate JSON data
  
Environment Variables:
  QS_PERF=1           Enable performance timing output
  QS_AUTO_QUIT=1      Auto-quit after model population (testing)
  QS_SHELL_ONLY=1     Skip QML interface
  DOCS_CATEGORY=category     Set default category
  DOCS_LANGUAGE=lang         Set default language
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
if [[ "$CATEGORY" != "root" && ! -d "$HOME/ddubsos/docs/$CATEGORY" ]]; then
  echo "Error: Category directory '$CATEGORY' not found in docs/" >&2
  echo "Available categories:" >&2
  echo "  root" >&2
  ls -1 "$HOME/ddubsos/docs/" | grep -E '^[a-zA-Z]' | head -10 >&2
  exit 1
fi
```

**Data Generation Pipeline**:
1. Create temporary directory with `mktemp -d`
2. Generate files JSON for current category and language using docs-parser
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

### 2. Documentation Parser (`docs-parser.nix`)

**Purpose**: Multi-format markdown parser that discovers and processes documentation files from the filesystem with metadata extraction.

#### Parser Architecture

**Entry Point**:
```bash
docs-parser MODE [CATEGORY] [LANGUAGE]

MODE: files|content|categories
CATEGORY: AI|ddubsos|root|etc.
LANGUAGE: en|es
```

#### Mode-Specific Processing

##### Files Mode Parser
**Purpose**: Generate JSON list of available files for a category
**File Discovery**: Uses `find` with `-print0` and `sort -z` for safe filename handling

**Root Category Processing**:
```bash
if [[ "$CATEGORY" == "root" ]]; then
  # Find markdown files directly in docs root directory
  if [[ -d "$DOCS_DIR" ]]; then
    first=true
    
    while IFS= read -r -d "" filepath; do
      file_lang=$(get_language "$filepath")
      
      # Filter by requested language
      if [[ "$file_lang" == "$LANGUAGE" ]]; then
        clean_name=$(get_clean_filename "$filepath")
        title=$(get_title_from_file "$filepath")
        
        # JSON output generation
      fi
    done < <(find "$DOCS_DIR" -maxdepth 1 -name "*.md" -print0 | sort -z)
  fi
fi
```

**Category Directory Processing**:
```bash
elif [[ -d "$DOCS_DIR/$CATEGORY" ]]; then
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
  done < <(find "$DOCS_DIR/$CATEGORY" -name "*.md" -print0 | sort -z)
fi
```

##### Content Mode Parser
**Purpose**: Extract file content with metadata for API access
**Content Processing**: Raw file reading with JSON encoding

```bash
if [[ -n "$FILENAME" ]]; then
  # Single file content
  if [[ -f "$DOCS_DIR/$CATEGORY/$FILENAME" ]]; then
    cat "$DOCS_DIR/$CATEGORY/$FILENAME"
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
  done < <(find "$DOCS_DIR/$CATEGORY" -name "*.md" -print0 | sort -z)
fi
```

##### Categories Mode Parser
**Purpose**: List all available categories dynamically
**Discovery Logic**: Filesystem-based category detection with root support

```bash
# Always include "root" category for files in docs/ root directory
if [[ -d "$DOCS_DIR" ]] && [[ $(find "$DOCS_DIR" -maxdepth 1 -name "*.md" | wc -l) -gt 0 ]]; then
  echo "    \"root\""
  first=false
fi

if [[ -d "$DOCS_DIR" ]]; then
  for dir in "$DOCS_DIR"/*; do
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
  
  # Remove category prefix (e.g., "AI.")
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

**Architecture**: Single-file QML application with embedded JavaScript logic for documentation browsing

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
property var docsFiles: []
property bool filesLoaded: false
property var availableCategories: []
```

#### Key Functions

**File Data Loading**:
```javascript
function loadDocsFiles() {
  console.log("Loading files for:", selectedCategory, selectedLanguage);
  
  var fileName = "files_" + selectedCategory + "_" + selectedLanguage + ".json";
  var filePath = tmpDir + "/" + fileName;
  
  const xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function() {
    if (xhr.readyState === XMLHttpRequest.DONE) {
      if (xhr.status === 200 || xhr.status === 0) {
        try {
          const result = JSON.parse(xhr.responseText);
          win.docsFiles = result;
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
    filePath = "/home/dwilliams/ddubsos/docs/" + filename;
  } else {
    filePath = "/home/dwilliams/ddubsos/docs/" + selectedCategory + "/" + filename;
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
  loadDocsFiles();
}

function switchLanguage(newLanguage) {
  selectedLanguage = newLanguage;
  selectedFile = "";
  fileContent = "";
  loadDocsFiles();
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
"float, class:^(org\\.qt-project\\.qml)$, title:^(Documentation Viewer)$"
"center, class:^(org\\.qt-project\\.qml)$, title:^(Documentation Viewer)$"
```

*Styling Rules (windowrulev2)*:
```nix
"noborder, class:^(org\\.qt-project\\.qml)$, title:^(Documentation Viewer)$"
"noshadow, class:^(org\\.qt-project\\.qml)$, title:^(Documentation Viewer)$"
"rounding 12, class:^(org\\.qt-project\\.qml)$, title:^(Documentation Viewer)$"
"opacity 0.95 0.95, class:^(org\\.qt-project\\.qml)$, title:^(Documentation Viewer)$"
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
docs-parser files CATEGORY LANGUAGE →
Filesystem Discovery → Markdown File Processing →
JSON Structure Generation → File Output
```

### 3. UI Data Flow
```
QML Component.onCompleted → loadDocsFiles() →
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
  "filename": "Warp-terminal-integration.md",
  "clean_name": "Warp-terminal-integration",
  "title": "Warp Terminal Integration with ddubsos",
  "category": "AI",
  "language": "en",
  "path": "/home/dwilliams/ddubsos/docs/AI/Warp-terminal-integration.md"
}
```

### Categories Array
```json
[
  "root",
  "AI",
  "ddubsos"
]
```

## Category System

### Available Categories
Based on filesystem structure in `~/ddubsos/docs/`:

- `root` - Files in the docs root directory
- `AI` - Artificial Intelligence tools and integration documentation
- `ddubsos` - ddubsos system documentation and guides

### Language Support
- `en` - English (default)
- `es` - Spanish (files ending in .es.md)

### File Naming Convention
- English: `Topic-name-description.md` (e.g., `Warp-terminal-integration.md`)
- Spanish: `Topic-name-description.es.md` (e.g., `Warp-terminal-integration.es.md`)

## Error Handling

### Shell Script Error Handling
```bash
set -euo pipefail  # Strict error handling

# Category validation
if [[ "$CATEGORY" != "root" && ! -d "$HOME/ddubsos/docs/$CATEGORY" ]]; then
  echo "Error: Category directory '$CATEGORY' not found in docs/" >&2
  echo "Available categories:" >&2
  ls -1 "$HOME/ddubsos/docs/" | grep -E '^[a-zA-Z]' | head -10 >&2
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
  win.docsFiles = result;
  win.filesLoaded = true;
  win.populateModel(win.docsFiles);
} catch (e) {
  console.error("Failed to parse files JSON:", e);
  console.log("Response text:", xhr.responseText);
  win.docsFiles = [];
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
mkdir -p ~/ddubsos/docs/newcategory
```

2. **Add Markdown Files**:
```bash
# English version
touch ~/ddubsos/docs/newcategory/New-Feature-Documentation.md

# Spanish version  
touch ~/ddubsos/docs/newcategory/New-Feature-Documentation.es.md
```

3. **Update Default Categories** (if needed):
```bash
# In qs-docs.nix, update usage text and validation
# Categories are automatically discovered, no code changes needed
```

### Adding New Languages

1. **Update Language Validation**:
```bash
# In qs-docs.nix
if [[ "$LANGUAGE" != "en" && "$LANGUAGE" != "es" && "$LANGUAGE" != "newlang" ]]; then
```

2. **Update File Detection**:
```bash
# In docs-parser.nix
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
docs-parser files AI en | jq '.'
docs-parser categories | jq '.'
docs-parser content AI en filename.md

# Shell-only mode for testing
QS_SHELL_ONLY=1 qs-docs -c AI -l en
```

**Performance Debugging**:
```bash
# Enable performance output
QS_PERF=1 qs-docs -c AI

# Auto-quit for testing
QS_AUTO_QUIT=1 qs-docs -c AI
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
**Solution**: Verify `loadDocsFiles()` function and file path construction for language variants

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
which qs-docs
which docs-parser

# Test categories
qs-docs -c AI
qs-docs -c ddubsos -l es
```

### Dependencies
- `pkgs.findutils` - File discovery
- `pkgs.gnugrep` - Text processing
- `pkgs.jq` - JSON processing (for content mode)
- `pkgs.coreutils` - Date, mktemp utilities
- QuickShell runtime - QML interface
- Qt 6.x - UI framework

### Content Directory Structure
The application reads from `~/ddubsos/docs/`:
```
docs/
├── AI/
│   ├── Warp-terminal-integration.md
│   ├── openwebui-ollama-setup.md
│   └── openwebui-ollama-setup.es.md
└── ddubsos/
    ├── qs-keybinds-app-code-overview-and-details.md
    └── Consider-Personal-Cacheix-cache.md
```

## Security Considerations

### Input Validation
- Category parameter validation against filesystem directories
- Language parameter validation against allowed values
- File path validation and sanitization
- Safe filename handling with null-terminated strings

### File Access
- Read-only access to documentation files
- Restricted to docs directory tree
- No arbitrary file system access
- Temporary directory with proper permissions

### Execution Context
- Runs in user context, no privilege escalation
- Sandboxed QML execution environment
- No external network access required
- Direct file system access only to designated directories

## Future Enhancements

### Potential Improvements
1. **Markdown Rendering**: Enhanced markdown parsing with syntax highlighting and live rendering
2. **Export Functionality**: Export documentation to PDF, HTML, or other formats
3. **Custom Categories**: User-defined category organization and tagging
4. **Advanced Search**: Regular expressions, full-text indexing, tag-based filtering
5. **Themes**: Customizable UI themes and typography options
6. **Bookmarking**: Favorite documents and quick access bookmarks
7. **Auto-Update**: Watch filesystem for new documentation files
8. **Collaboration**: Share and sync documentation across devices
9. **Cross-References**: Automatic linking between related documents
10. **Version Control**: Integration with git for document versioning

### Architecture Scalability
- Modular parser design allows easy format extension
- QML component architecture supports additional UI features
- JSON data format provides flexible data exchange
- Nix build system enables reproducible deployments
- Filesystem-based content allows easy maintenance and backup

## Conclusion

The `qs-docs` application provides a robust, extensible platform for technical documentation viewing with real-time search and multilingual support. Its simple filesystem-based architecture, efficient search capabilities, and clean UI make it ideal for managing project documentation, development notes, and technical guides. The application's focus on developer workflows and system documentation makes it an essential tool for maintaining organized technical knowledge bases. The detailed documentation and maintenance procedures ensure long-term sustainability and ease of enhancement.

---

## 2025-09 Rendering and Search Overhaul

This release mirrors the qs-cheatsheets improvements for Markdown fidelity and search UX.

Summary of changes:
- Markdown is pre-converted to HTML via pandoc for accurate rendering of code blocks, tables, lists, and nested elements.
- The viewer switches from MarkdownText to RichText, rendering the generated HTML.
- Inline highlight spans are removed. A Matches panel provides clickable snippets and approximate jump-to navigation.
- New properties and models support the UX.

### Rendering pipeline (Markdown → HTML → RichText)

- Startup now includes conversion of discovered markdown files to HTML under the session temp directory:
  - $TMPDIR/html/<category>/<language>/<file>.html
  - Uses pandoc (GFM) with a sed fallback to escaped <pre>.
- QML loads raw markdown for searching and pre-converted HTML for display; HTML is preferred, with a safe <pre> fallback.

Launcher helper (added):
```bash
convert_markdown_sets() {
  for json in "$tmpdir"/files_*.json; do
    [ -f "$json" ] || continue
    name=$(basename "$json")
    category="''${name#files_}"
    category="''${category%_*}"
    language="''${name##*_}"
    language="''${language%.json}"
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

Dependencies added: pandoc, jq, sed.

### QML model and properties

- htmlContent: string (HTML by pandoc)
- fileContent: string (raw markdown; used for search)
- displayedContent: string (display output)
- matchesModel: ListModel of { idx, start, snippet }

Display logic:
```js
function rebuildDisplayedContent() {
  if (!fileContent || fileContent.length === 0) { displayedContent = ""; return; }
  if (htmlContent && htmlContent.length > 0) { displayedContent = htmlContent; }
  else { displayedContent = "<pre style=\"white-space:pre-wrap;\">" + escapeHtml(fileContent) + "</pre>"; }
}
```

### Viewer: RichText (TextEdit)
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

### Search UX: Matches panel + approximate jump

- updateSearch() computes matchPositions and builds matchesModel with ~80-char snippets per hit.
- Jumping uses (start/fileContent.length) to set contentY proportionally.
- Prev/Next invoke jumpToMatch(index).

Core functions excerpt:
```js
function updateSearch() {
  matchPositions = []; searchCount = 0; currentMatchIndex = 0; matchesModel.clear();
  if (!fileContent || !searchQuery || searchQuery.trim() === "") { rebuildDisplayedContent(); return; }
  var needle = String(searchQuery).toLowerCase();
  var hay = String(fileContent).toLowerCase();
  var idx = 0; let pos;
  while ((pos = hay.indexOf(needle, idx)) !== -1) { matchPositions.push([pos, pos + needle.length]); idx = pos + needle.length; }
  searchCount = matchPositions.length;
  for (var j = 0; j < matchPositions.length; j++) {
    var s = matchPositions[j][0], e = matchPositions[j][1];
    var ctxStart = Math.max(0, s - 80), ctxEnd = Math.min(fileContent.length, e + 80);
    var snippet = fileContent.slice(ctxStart, ctxEnd).replace(/\n/g, " ");
    matchesModel.append({ idx: j, start: s, snippet: snippet });
  }
  currentMatchIndex = (searchCount > 0) ? 0 : 0; rebuildDisplayedContent();
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
  if (typeof matchesList !== 'undefined' && matchesList) { matchesList.positionViewAtIndex(currentMatchIndex, ListView.Center); }
}
```

Trade-offs and tips:
- Approximate jump is fast but not pixel-perfect on very long pages. Future improvement could include heading anchors or height estimation.
- If HTML looks plain, ensure pandoc is available and conversion ran (check $TMPDIR/html/... path).
- Nix escaping: parameter expansions inside Nix strings must be written as ''${...}.

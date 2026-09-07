# QuickShell Keybinds Menu

A searchable, interactive menu for viewing Hyprland and Emacs keybinds using QuickShell.

## Features

- **Dual Mode Support**: Switch between Hyprland and Emacs keybinds
- **Search Functionality**: Real-time search across keybinds, descriptions, and categories
- **Category Organization**: Color-coded categories for easy navigation
- **Clipboard Integration**: Click any keybind to copy it to clipboard
- **Desktop Notifications**: Visual feedback when keybinds are copied
- **Responsive Interface**: Fast, frameless QuickShell window

## Usage

### Basic Usage
```bash
# Launch with default mode (Hyprland)
qs-keybinds

# Launch with specific mode
qs-keybinds -m hyprland
qs-keybinds -m emacs

# Show help
qs-keybinds -h
```

### Hyprland Keybinding
- **SUPER + SHIFT + K**: Launch the keybinds menu (configured in Hyprland binds)

### Interface Controls
- **ESC**: Quit the application
- **Search Bar**: Type to filter keybinds by name, description, or category
- **Mode Buttons**: Click "Hyprland" or "Emacs" to switch modes
- **Keybind Items**: Click any keybind to copy it to clipboard

## Categories

### Hyprland Categories
- **Terminal**: Terminal applications (foot, wezterm, ghostty)
- **Browser**: Web browsers
- **Editor**: Text editors (Emacs, VS Code)
- **Screenshot**: Screenshot tools
- **Launcher**: Application launchers and menus
- **Wallpaper**: Wallpaper management tools
- **Media**: Audio/video controls and brightness
- **Window**: Window management (move, resize, kill, etc.)
- **Workspace**: Workspace navigation and management
- **App**: General applications

### Emacs Categories
- **Files**: File operations and management
- **Project**: Project-related commands
- **Buffers**: Buffer management
- **Windows**: Window splitting and navigation
- **Search**: Search and replace operations
- **Git**: Git/Magit integration
- **Help**: Help and documentation
- **Code**: Code navigation and actions
- **Quit**: Exit operations

## Technical Details

### Architecture
1. **keybinds-parser**: Runtime parsing of actual config files using AWK
2. **qs-keybinds**: QML interface that loads data via XMLHttpRequest 
3. **Integration**: Seamless clipboard and notification support

### How It Works
1. **Runtime Parsing**: Parser reads live config files (not Nix sources)
2. **JSON Generation**: Clean JSON output with proper categorization
3. **QML Loading**: Interface loads JSON data dynamically at startup
4. **Search & Filter**: Real-time filtering across all keybind properties

### Data Sources
- **Hyprland**: Parses `~/.config/hypr/hyprland.conf` at runtime
- **Emacs**: Curated list of comprehensive Doom Emacs leader keybinds

### Performance
- **Lazy Loading**: Keybinds are parsed on demand
- **Caching**: Efficient JSON generation and caching
- **Shell-only Mode**: Available for debugging (`--shell-only`)

## Configuration

### Environment Variables
- `KEYBINDS_MODE`: Default mode (hyprland|emacs)
- `QS_DEBUG`: Enable debug output
- `QS_PERF`: Enable performance timing

### Customization
The parser automatically categorizes keybinds based on their actions. Categories and colors can be customized in the QML interface.

## Development

### Adding New Categories
Edit the `getCategoryColor()` function in `qs-keybinds.nix` to add new categories and colors.

### Extending Emacs Keybinds
Modify the `parse_emacs_keybinds()` function in `keybinds-parser.nix` to add more keybinds.

### Testing
```bash
# Test parser directly
keybinds-parser hyprland
keybinds-parser emacs

# Test interface without GUI
qs-keybinds --shell-only
```

## Integration

The keybinds menu is integrated into:
- Hyprland configuration (SUPER + SHIFT + K)
- Home Manager scripts collection
- Existing `list-keybinds` command (now uses qs-keybinds)

## Troubleshooting

### Common Issues
1. **QML not found**: Ensure Qt6 packages are available
2. **Keybinds not showing**: Check that configuration files exist
3. **Categories wrong**: Parser rules may need adjustment

### Debug Mode
```bash
QS_DEBUG=1 qs-keybinds
```

### Performance Analysis
```bash
QS_PERF=1 qs-keybinds
```
# qs-wlogout - Quickshell WLogout Implementation

This module provides a faithful recreation of [wlogout](https://github.com/ArtsyMacaw/wlogout) using Quickshell and QML, replacing the need for the original wlogout package.

## Features

- **6 Action Buttons**: Lock, Logout, Suspend, Hibernate, Shutdown, Reboot
- **Keyboard Navigation**: Each button has a keyboard shortcut (L, E, U, H, S, R respectively)
- **Multi-Monitor Support**: Displays on all connected screens
- **Wayland Layer Shell**: Uses overlay layer with exclusive keyboard focus
- **Customizable Icons**: Icons can be customized by replacing files in the icons directory
- **Environment Configuration**: Configurable through environment variables

## Usage

### Basic Usage
```bash
# Launch the wlogout interface
qs-wlogout

# Show help
qs-wlogout -h
```

### Keyboard Shortcuts
- **L** - Lock session (`loginctl lock-session`)
- **E** - Logout (`loginctl terminate-user $USER`)
- **U** - Suspend (`systemctl suspend`)
- **H** - Hibernate (`systemctl hibernate`)
- **S** - Shutdown (`systemctl poweroff`)
- **R** - Reboot (`systemctl reboot`)
- **Escape** - Cancel and close

### Configuration

#### Environment Variables
- `QS_DEBUG=1` - Enable debug output
- `QS_WLOGOUT_ICONS_DIR` - Override icons directory (default: `~/.local/share/qs-wlogout/icons`)
- `QS_WLOGOUT_QML_DIR` - Override QML directory (default: `~/.local/share/qs-wlogout`)

#### Command Line Options
- `-i DIR` - Specify icons directory
- `-q DIR` - Specify QML files directory
- `-h` - Show help

### Customization

#### Custom Icons
Replace the PNG files in `~/.local/share/qs-wlogout/icons/`:
- `lock.png` - Lock screen icon
- `logout.png` - Logout icon  
- `suspend.png` - Suspend icon
- `hibernate.png` - Hibernate icon
- `shutdown.png` - Shutdown icon
- `reboot.png` - Reboot icon

Icons should be square PNG files (64x64 or larger recommended).

#### Style Customization
The module generates QML files at runtime in a temporary directory. To customize the appearance:
1. Set `QS_DEBUG=1` to see where temporary files are created
2. Copy the generated QML files to your custom QML directory
3. Modify colors, layout, and styling in the QML files
4. Use `qs-wlogout -q /path/to/custom/qml/dir` to use your customized version

## Integration with ddubsos

The module is automatically included in the ddubsos home-manager configuration. After rebuilding your system, the `qs-wlogout` command will be available in your PATH.

### Hyprland Integration
Add a keybinding to your Hyprland configuration:
```
bind = SUPER, X, exec, qs-wlogout
```

### Waybar Integration
Add a button to your Waybar configuration:
```json
"custom/wlogout": {
    "format": "⏻",
    "on-click": "qs-wlogout",
    "tooltip": "Power menu"
}
```

## Troubleshooting

### Common Issues

**Error: quickshell not found**
- Ensure quickshell is installed and available in PATH
- Check that the quickshell module is enabled in your ddubsos configuration

**Icons not displaying**
- Check that icon files exist in `~/.local/share/qs-wlogout/icons/`
- Verify icon file permissions are readable
- Use `QS_DEBUG=1` to see debug output about icon copying

**QML errors**
- Use `QS_DEBUG=1` to see detailed output
- Check that Qt6 and required QML modules are installed
- Verify Wayland is running (required for layer shell)

### Debug Mode
```bash
QS_DEBUG=1 qs-wlogout
```

This will show:
- Icon directory paths
- QML file locations  
- Quickshell binary path
- Any errors during execution

## Dependencies

The module requires:
- `quickshell` - QML shell framework
- `qt6.qtbase` - Qt6 base
- `qt6.qtdeclarative` - QML engine
- `qt6.qtwayland` - Wayland support
- `imagemagick` - For fallback icon generation (if needed)

These are automatically handled by the ddubsos configuration.

## Differences from Original wlogout

- **Implementation**: Uses Quickshell/QML instead of GTK
- **Configuration**: Environment variables instead of config files
- **Icons**: PNG files instead of configurable icon themes
- **Styling**: QML-based styling instead of CSS
- **Performance**: Faster startup due to QML compilation

## Contributing

The module is located in `modules/home/scripts/qs-wlogout.nix` and follows the same patterns as other ddubsos quickshell modules like `qs-wallpapers` and `qs-vid-wallpapers`.

# Warp Terminal Current Integration

This document describes the integration of `warp-terminal-current` into ddubsos, providing access to the bleeding-edge version of Warp Terminal.

## Integration Summary

### What Was Added

1. **Flake Input**: `warp-terminal-current` pointing to `github:dwilliam62/war-terminal/dev`
2. **Overlay Package**: `pkgs.warp-terminal-current` exposed through ddubsos overlay system
3. **Optional Module**: `modules/apps/warp-terminal-current.nix` for user opt-in
4. **GUI Integration**: Desktop file and custom icon for "Warp-bld" launcher
5. **Documentation**: Complete usage and troubleshooting docs

### Files Modified/Created

```
ddubsos/
├── flake.nix (added input)
├── modules/core/overlays.nix (added package)
├── modules/apps/warp-terminal-current.nix (new)
├── modules/apps/warp-terminal-current.md (new)
└── WARP_TERMINAL_INTEGRATION.md (this file)
```

## Usage for Users

### Enabling the Current Version

Add to your host configuration or user modules:

```nix
programs.warp-terminal-current = {
  enable = true;
  waylandSupport = true;
};
```

### Standard Workflow

```bash
# Update all flake inputs (including warp-terminal-current)
zcli update

# Rebuild system with latest packages
zcli rebuild
```

## Technical Details

### Package Source
- **Repository**: https://github.com/dwilliam62/war-terminal
- **Branch**: `dev` 
- **Package Name**: `warp-terminal-current`
- **Update Mechanism**: Via ddubsos flake update process

### Integration Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ war-terminal    │    │ ddubsos flake    │    │ User Config     │
│ (dev branch)    │───▶│ input + overlay  │───▶│ opt-in module   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

1. **war-terminal** maintains packaging and version updates
2. **ddubsos** exposes as `pkgs.warp-terminal-current` via overlay
3. **Users** enable via `programs.warp-terminal-current.enable = true`

### Differences from Stable

| Aspect | Stable (`warp-terminal`) | Current (`warp-terminal-current`) |
|--------|-------------------------|-----------------------------------|
| Source | nixpkgs | war-terminal flake |
| Updates | NixOS release cycle | Every flake update |
| Versions | Stable/tested | Latest upstream |
| Desktop Entry | "Warp Terminal" | "Warp-bld" |
| Icon | `warp-terminal` | `warp-terminal-bld` (custom) |
| GUI Launcher | Standard appearance | Distinct with bleeding-edge indicators |

## Benefits

1. **Non-invasive**: Doesn't affect existing `warp-terminal` users
2. **ddubsos Native**: Follows established patterns and workflows
3. **Automatic Updates**: Gets latest version via `zcli update`
4. **Optional**: Users must explicitly enable
5. **Rollback Safe**: NixOS generation rollback works normally

## Maintenance

### For Regular Updates
Users just run their normal ddubsos workflow:
```bash
zcli update && zcli rebuild
```

### For Version Issues
If warp-terminal-current has issues, users can:
1. **Temporarily disable**: Set `programs.warp-terminal-current.enable = false`
2. **Use stable**: Install regular `warp-terminal` from nixpkgs  
3. **Rollback generation**: Use NixOS rollback if needed

### For Maintainers
- **war-terminal repo**: Handles upstream packaging and version tracking
- **ddubsos**: Simply pulls latest from war-terminal flake input
- **Hash updates**: Automated through war-terminal update scripts

## Security Notes

The war-terminal project has been thoroughly audited:
- ✅ Uses official Warp Terminal release URLs
- ✅ Proper SHA256 hash verification
- ✅ Standard NixOS packaging patterns
- ✅ No privilege escalation or malicious code
- ✅ Transparent, readable source

## Testing

To test the integration:

```bash
# Check that package is available
nix eval .#packages.x86_64-linux.warp-terminal-current.name

# Build without installing
nix build .#packages.x86_64-linux.warp-terminal-current --no-link

# Test in development environment
nix develop github:dwilliam62/war-terminal/dev
```

## Future Enhancements

Potential improvements:
- [ ] Add CI/CD for automatic version updates
- [ ] Integration with ddubsos update notifications
- [ ] Per-user configuration options
- [ ] Custom build variants (e.g., debug builds)

## Rollback Plan

If integration causes issues:
1. Disable module: `programs.warp-terminal-current.enable = false`
2. Remove from flake inputs if needed
3. Use NixOS generation rollback
4. Fall back to stable `warp-terminal` from nixpkgs

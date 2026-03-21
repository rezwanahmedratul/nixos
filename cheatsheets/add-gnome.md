# Add GNOME Desktop (overview)

This guide gives **basic steps** and **which files to edit** to add GNOME to ZaneyOS.

In NixOS, you enable it through NixOS options in a module (a `.nix` file), then pick a display manager (login screen).  
This repo already has **SDDM** (graphical) and **LY** (text) login support. You can keep using either — both can start GNOME sessions.

## Files to edit (minimal list)

1. `modules/core/default.nix`
   - Import your new GNOME module so it becomes part of the system config.

2. `modules/core/xserver.nix`
   - GNOME needs `services.xserver.enable = true;` (this file currently disables X11).

3. `modules/core/gnome.nix` (new file you create)
   - Turn on GNOME’s desktop manager.

4. `hosts/<hostname>/variables.nix`
   - Make sure your `displayManager` is set to either `"sddm"` or `"tui"` (for LY), since those are already supported here.

## Suggested minimal GNOME module (example)

```nix path=null start=null
{ ... }:
{
  services.xserver = {
    enable = true;
    desktopManager.gnome.enable = true;
  };
}
```

## Where to import the GNOME module

In `modules/core/default.nix`, add your GNOME file to the imports list:

```nix path=null start=null
imports = [
  # ...
  ./gnome.nix
  # ...
];
```

## Flatpak: GNOME Extensions Manager

To add the Flatpak app **Extension Manager** (for GNOME extensions), edit `modules/core/flatpak.nix` and add its ID:

```nix path=null start=null
services.flatpak.packages = [
  "com.mattjakeman.ExtensionManager"
];
```

## `git add .` and rebuild

Once you have the file created. In the ZaneyOS directory run `git add . ` then `zcli rebuild`

# HOWTO: Add New Application Icons to Workspaces (for Waybars that support them)

[Leer en español](./HOTWO-Add-New-Application-Icons-to-Workspaces-on-Waybars-that-support-them.es.md)

This guide explains how the “app icon per window” feature works in your Waybar configs, which files to edit, how to find an app’s identifiers (class/title), and how to add new icon mappings. Includes examples and a Spanish translation at the end.

Important:
- Only certain Waybar themes in this repo support per-app icons in the workspace list (those that use window-rewrite rules). The Jak-based variants do; several others show workspace names/numbers only.
- You can add new mappings globally (shared file) and/or locally (specific theme file).


## 1) Which Waybars support per-app workspace icons?
These Waybar configs include a hyprland/workspaces block with window-rewrite rules (this is what maps apps to icons):
- modules/home/waybar/waybar-jak-catppuccin.nix
- modules/home/waybar/waybar-jak-ml4w-modern.nix
- modules/home/waybar/waybar-jak-oglo-simple.nix
- Shared rules: modules/home/waybar/jak-waybar/ModulesWorkspaces

Other themes (e.g., waybar-ddubs.nix, waybar-ddubs-2.nix, waybar-simple.nix, waybar-curved.nix, waybar-tony.nix, waybar-dwm*.nix, waybar-mecha.nix, waybar-jwt-*.nix) do not use window-rewrite; they render workspace labels or numbers instead of per-window icons.


## 2) How does it work?
Waybar’s hyprland/workspaces module supports regex rewrite rules:
- window-rewrite-default: fallback icon when no rule matches.
- window-rewrite: a map of regex selectors → icon strings.
- Common selectors used here:
  - class<...> to match window class (WM_CLASS / Hyprland class)
  - title<...> to match window title

Example (Nix fragment inside a Waybar settings block):
```nix
"hyprland/workspaces#rw" = {
  format = "{icon} {windows}";
  "format-window-separator" = " ";
  "window-rewrite-default" = " ";
  "window-rewrite" = {
    "class<firefox|org.mozilla.firefox>" = " ";
    "class<discord|Vesktop>" = " ";
    "title<.*YouTube.*>" = " ";
  };
};
```


## 3) Where to edit
You can add rules in one or both places:
- Global (shared):
  - modules/home/waybar/jak-waybar/ModulesWorkspaces
  - Pros: One edit propagates to all Jak-based themes that import these rules.
- Theme-specific:
  - modules/home/waybar/waybar-jak-catppuccin.nix
  - modules/home/waybar/waybar-jak-ml4w-modern.nix
  - modules/home/waybar/waybar-jak-oglo-simple.nix
  - Pros: Only affects a single theme; good for experiments.

Tip: If a theme duplicates (inlines) rules, prefer updating both the shared ModulesWorkspaces and the active theme, so behavior stays consistent.


## 4) Find an app’s class and title
On Hyprland, use hyprctl:
```bash
hyprctl clients -j | jq '.[] | {class: .class, title: .title}'
```
- class is what you can match with class<...>
- title is what you can match with title<...>

Examples:
- Flatpak Signal often shows class org.signal.Signal
- Native Signal may use signal-desktop
- Some apps change titles per tab/document; class is typically more stable


## 5) Choosing an icon
- Use a glyph from Nerd Fonts or similar icon sets already in use.
- Keep icons short (1–2 glyphs plus a trailing space) to align well in the bar, e.g., "󰍩 " or " ".
- Optional: color can be applied via markup, but most rules here keep plain text for consistency.


## 6) Add a new mapping (step-by-step)
Example: Add an icon for Signal Desktop

A) Update the shared rules (recommended)
- File: modules/home/waybar/jak-waybar/ModulesWorkspaces
- Find the "hyprland/workspaces#rw" → "window-rewrite" map
- Add class/title patterns for Signal:
```jsonc
"window-rewrite": {
  // ... existing entries ...
  "class<[Ss]ignal|signal-desktop|org.signal.Signal>": "󰍩 ",
  "title<.*Signal.*>": "󰍩 ",
}
```
Why both? Class matching is reliable, but the title rule covers edge cases.

B) Update a theme that inlines rules (if applicable)
- File(s):
  - modules/home/waybar/waybar-jak-catppuccin.nix
  - modules/home/waybar/waybar-jak-ml4w-modern.nix
  - modules/home/waybar/waybar-jak-oglo-simple.nix
- Find the hyprland/workspaces block with "window-rewrite" and add the same entries.

C) Rebuild and reload Waybar
- In this repository, Home Manager is managed as a NixOS module, so rebuild via NixOS:
```bash
zcli rebuild
# or: sudo nixos-rebuild switch --flake .#<host>
```
- Then restart Waybar if needed:
```bash
systemctl --user restart waybar.service
# or: pkill waybar
```


## 7) Testing & troubleshooting
- Launch the target app on some workspace and confirm the icon appears near the workspace button.
- If the icon doesn’t render:
  - Confirm your active theme is one of the Jak-based configs with window-rewrite rules.
  - Confirm the rule regex matches your window’s class/title (re-check with hyprctl clients -j).
  - Ensure your font supports the chosen glyph (Nerd Font configured by your Waybar CSS).
  - Check for stray quotes or commas in the Nix/JSON blocks.


## 8) Common patterns you can copy
- Multiple classes in one rule (regex alternation):
```jsonc
"class<Chromium|Thorium|[Cc]hrome>": " ",
```
- Case-insensitive-ish match (e.g., both Signal and signal):
```jsonc
"class<[Ss]ignal>": "󰍩 ",
```
- Title contains substring:
```jsonc
"title<.*YouTube.*>": " ",
```


# HOWTO: Customize Kitty (ddubsOS)

This repo manages Kitty via Home Manager at modules/home/terminals/kitty.nix. It ships with a Catppuccin Mocha theme embedded in extraConfig and sane defaults (font Maple Mono NF, size 12, powerline tabs, scrollback 10k, URL handling, shell integrations).

Section 1 — Quick manual edits (font, size, behavior)
- Edit modules/home/terminals/kitty.nix → programs.kitty.settings
  - font_family = "Maple Mono NF";   # change to any installed font
  - font_size = 12;                   # adjust size
  - window_padding_width, tab_bar_style, scrollback_lines, etc.
- Apply changes: zcli rebuild (preferred) or nh os switch.

Section 2 — Manual color theming (replace the embedded Catppuccin block)
- In modules/home/terminals/kitty.nix, programs.kitty.extraConfig contains a full Catppuccin palette (foreground/background/color0..15, tab colors, borders).
- Option A: Keep everything in Nix
  - Replace those color lines with your own palette.
  - Example keys you should set: foreground, background, selection_foreground, selection_background, cursor, active_border_color, inactive_border_color, active_tab_foreground/background, inactive_tab_foreground/background, color0..color15.
- Option B: Include a separate theme file that you maintain in ~/.config/kitty
  - Remove or comment the color block in extraConfig and add:
    include current-theme.conf
  - Create ~/.config/kitty/current-theme.conf with your colors (or let the kitten in Section 3 write it for you).
- Apply changes: zcli rebuild or nh os switch.

Section 3 — Using the built-in "kitty +kitten themes"
This is the easiest way to browse/apply hundreds of themes.
1) Ensure your kitty.conf includes an "include" for the theme file:
   - Edit modules/home/terminals/kitty.nix and in programs.kitty.extraConfig:
     - Remove the hardcoded Catppuccin color block
     - Add: include current-theme.conf
2) Rebuild: zcli rebuild or nh os switch
3) In a Kitty window, run:
   kitty +kitten themes --reload-in=all
   - Navigate with arrow keys, press Enter to preview
   - Press s to save; by default it writes current-theme.conf under ~/.config/kitty/
4) Persisted theme loads on next launch because kitty.conf includes current-theme.conf.

Notes and tips
- Live apply a theme file without restart:
  kitty @ set-colors --all ~/.config/kitty/current-theme.conf
- If colors seem overridden, ensure there are no other color directives after your include in extraConfig.
- If using Stylix theming elsewhere, keep Kitty’s colors either fully managed by Stylix or by a single include to avoid conflicts.

References
- Module source: modules/home/terminals/kitty.nix
- Cheatsheet: cheatsheets/kitty/kitty.cheatsheet.md

Appendix — Samples and snippets

Sample: tweak fonts and scrollback (Nix)
```nix
# In modules/home/terminals/kitty.nix
programs.kitty.settings = {
  font_family = "JetBrainsMono Nerd Font";
  font_size = 13;
  tab_bar_style = "fade";
  scrollback_lines = 20000;
};
```

Sample: minimal dark palette (kitty syntax)
```conf
# Minimal dark theme
foreground              #d0d0d0
background              #111216
active_border_color     #8aadf4
inactive_border_color   #3b3d4b
active_tab_foreground   #0e0f13
active_tab_background   #a6e3a1
inactive_tab_foreground #c0c4ce
inactive_tab_background #1a1b22

# core 16-color palette
color0  #1b1d24
color8  #3b3d4b
color1  #ff6b6b
color9  #ff8787
color2  #a6e3a1
color10 #b1f0ad
color3  #f9e2af
color11 #ffe7a3
color4  #89b4fa
color12 #9ac1ff
color5  #f5c2e7
color13 #f8c8ee
color6  #94e2d5
color14 #9fe9dc
color7  #c6cad6
color15 #e6e9ef
```

Sample: switch to a separate theme file
```conf
# In extraConfig
include current-theme.conf
```
Then create `~/.config/kitty/current-theme.conf` with your colors, or use the themes kitten to write it.

Kitten quick actions
```bash
# Browse/apply themes and save to current-theme.conf
kitty +kitten themes --reload-in=all
# Live apply any theme file to all windows
echo "" | kitty @ set-colors --all ~/.config/kitty/current-theme.conf
```

Background image launcher quick reference
```bash
kitty-bg                          # pick random wallpaper, launch in background
kitty-bg --no-launch              # only update the wallpaper symlink
kitty-bg -s ~/Pictures/Wallpapers/Space
kitty-bg -l ~/Pictures/current_image
kitty-bg --foreground -- -e htop  # pass args after -- to kitty
```

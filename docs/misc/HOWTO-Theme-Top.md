# HOWTO: Theme procps-ng top (English)

Audience: ddubsOS users on Linux using procps-ng top. This guide shows quick keys to get colorful bar graphs like htop, how to save, where the rcfile lives, and how this repo preserves your theme via Home Manager.

TL;DR
- Start top
- Press:
  - t: CPU summary → bars
  - m: Memory summary → bars
  - 1: Per-CPU lines
  - z: Toggle color on/off
  - Shift+Z: Color setup menu (change colors per group)
  - x: Highlight sort column; y: show sort field name
  - Shift+W: Save to ~/.config/procps/toprc


1) Basics: enable bars and colors
- CPU bars: press t repeatedly to cycle through CPU summary modes until you see bar graphs.
- Memory bars: press m repeatedly to cycle memory summary until you see bars for Mem/Swap.
- Per-CPU view: press 1 to expand CPUs into separate lines.
- Color mode: press z to toggle color globally.
- Color tuning: press Shift+Z (uppercase Z) to open the color configuration menu. Pick a group (Summary, Messages, Header, Task) and adjust fg/bg/bold as desired. Press q to exit.
- Save your layout/colors: press Shift+W (uppercase W).

Tip: If colors look odd with your terminal theme, use Shift+Z to change the palette interactively, then Shift+W to persist.


2) Sorting, fields, and readability
- Highlight sort column: x
- Show current sort field name in header: y
- Choose sort field: press F (uppercase) or f to open the Fields/Sort menu, then select the field to sort by (e.g., %CPU, %MEM, TIME+). Confirm and exit.
- Add/remove columns: f (Fields) toggles visibility per column.
- Reorder columns: o (lowercase) in the Fields menu lets you change the column order interactively.
- Show command line vs program name: c
- Show threads: H
- Hide idle tasks: i
- Forest (tree) view: V

Notes: Key behavior can vary slightly by procps-ng version; the above is the typical mapping. Use h while in top for the built-in help.


3) Units and display niceties
- Scale memory units: E (global) and/or e (task area) cycles through KiB/MiB/GiB.
- Accumulate CPU time: S toggles cumulative mode for processes.
- Irix vs Solaris mode (CPU percent normalization): I toggles whether processes can exceed 100% on multi-core systems.


4) Where the config is saved
- Procps-ng top writes to the XDG config path:
  - ~/.config/procps/toprc
- Older documentation sometimes references ~/.toprc, but your build uses the procps path above.


5) Troubleshooting
- "incompatible rcfile" error: remove the current rc so top can regenerate a fresh one, then re-customize and save.
  ```bash path=null start=null
  rm -f ~/.config/procps/toprc
  # Restart top, re-apply t/m/1/z/Z, then Shift+W to save
  ```
- No bars or colors: press t and m for bars, z for color. Some terminals/themes may reduce contrast; use Shift+Z to adjust.
- Per-CPU missing: press 1.


6) Preserving your theme in this repo (ddubsOS Home Manager)
This repo includes a small Home Manager activation that helps preserve your top theme without making it read-only:
- Location in repo: modules/home/cli/procps-toprc.nix
- Behavior (seed-once, RW-friendly):
  - If ~/.config/procps/toprc exists and the repo does NOT have a copy yet, it copies live → repo on rebuild (first capture).
  - If the repo has a copy and your home file is missing, it installs repo → ~/.config/procps/toprc (first seed).
  - Once both exist, it leaves them alone so you can keep using Shift+W in top.

Update the repo copy when you’re happy with changes:
```bash path=null start=null
cp ~/.config/procps/toprc ~/ddubsos/modules/home/cli/procps-toprc
# Then rebuild so the repo version is tracked by your system config
zcli rebuild
```


7) Example workflow
1. Run top, press t, m, 1, z, Shift+Z to tweak colors.
2. Press Shift+W to save.
3. Run zcli rebuild. The activation detects and captures your live toprc into the repo if it’s missing there.
4. Commit the repo copy if desired.


Appendix: Key reference (common)
- Bars/colors: t (CPU), m (Mem), 1 (per-CPU), z (color), Z (color setup)
- Sort/fields: x (highlight), y (show field), f/F (fields/sort menu), o (order), R (reverse)
- Views/filters: c (cmdline), H (threads), i (hide idle), V (forest)
- Units/modes: E/e (units), S (cumulative), I (Irix vs Solaris)
- Save: W


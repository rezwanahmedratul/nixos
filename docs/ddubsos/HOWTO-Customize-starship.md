# HOWTO: Customize Starship (ddubsOS)

This repo manages Starship via Home Manager with selectable configs:
- Default: modules/home/cli/starship.nix (accent derives from Stylix: config.lib.stylix.colors.base0D)
- Catppuccin: modules/home/cli/starship-catppuccin.nix (full Catppuccin Mocha palette)

Section 1 — Pick a Starship config per host
1) Edit hosts/<host>/variables.nix
2) Set one of:
   starshipChoice = ../../modules/home/cli/starship.nix;
   #starshipChoice = ../../modules/home/cli/starship-catppuccin.nix;
3) Apply: zcli rebuild or nh os switch

Section 2 — Customize colors
- starship.nix
  - Top defines: accent = "#${config.lib.stylix.colors.base0D}"; background-alt = "#${config.lib.stylix.colors.base01}";
  - To hardcode: set accent = "#89b4fa"; background-alt = "#313244"; (or any hex)
  - Modules using these: directory.style = accent; git_branch.style = "fg:${accent} bg:${background-alt}"; character.success_symbol = "[❯](${accent})"
- starship-catppuccin.nix
  - palette = "catppuccin_mocha"; palettes.catppuccin_mocha defines all named colors
  - Use names in styles, e.g. "bold mauve", "peach", "subtext1"
  - Adjust directory.style, git_branch.style, character symbols, etc.

Section 3 — Change prompt layout and modules
- format controls order; examples:
  - starship.nix: format = "$nix_shell$hostname$directory$git_branch$git_state$git_status\n$character"
  - catppuccin: format = "$all$custom$character" (puts everything before the prompt symbol)
- To add time on the right:
  right_format = "[$time]($style)";
  time = { disabled = false; format = "[$time]($style)"; time_format = "%H:%M"; style = "subtext1"; }
- Enable/disable modules:
  python.disabled = true; nix_shell.disabled = true; os.disabled = true;
- Change symbols:
  character = { success_symbol = "[❯](peach)"; error_symbol = "[❯](red)"; vimcmd_symbol = "[❮](cyan)"; }

Section 4 — Custom modules and detection
- starship-catppuccin.nix has examples under settings.custom: json, yaml, nix
- To add your own:
  custom.mytool = { symbol = "⚙ "; style = "bold teal"; format = "[$symbol]($style)"; detect_files = ["mytool.toml"]; };

Section 5 — Apply and verify
- Rebuild: zcli rebuild or nh os switch
- Open a new shell or exec zsh to reload prompt
- Debug your prompt:
  starship explain            # shows which modules rendered and why
  starship print-config | bat # see merged config after HM renders

Notes
- enableZshIntegration = true is set in catppuccin config; the default config relies on Home Manager’s programs.starship.enable to initialize your shell.
- If colors don’t match expectations with Stylix, prefer hardcoding hex values or using the Catppuccin config’s named palette.

References
- Configs: modules/home/cli/starship.nix, modules/home/cli/starship-catppuccin.nix
- Host toggle: hosts/<host>/variables.nix (starshipChoice)

Samples and common tweaks

Change Git colors (Nix)
```nix
# In modules/home/cli/<your-starship>.nix
programs.starship.settings = {
  git_branch = {
    symbol = " ";
    style = "bold fg:#89b4fa bg:#313244"; # customize here
    format = "on [$symbol$branch]($style) ";
  };
  git_status = {
    style = "yellow";                 # or a hex, e.g. fg:#ffd166
    format = "[($conflicted$untracked$modified$staged$renamed$deleted)]($style)$ahead_behind$stashed ";
    stashed = "≡";
  };
  git_state = {
    style = "italic red";
    format = "([$state( $progress_current/$progress_total)]($style)) ";
  };
};
```

Override accent/background used by multiple modules (Nix)
```nix
let
  accent = "#89b4fa";
  background-alt = "#313244";
in {
  programs.starship.settings = {
    directory.style = accent;
    git_branch.style = "fg:${accent} bg:${background-alt}";
  };
}
```

Add a right prompt clock and tweak symbols
```nix
programs.starship.settings = {
  right_format = "[$time]($style)";
  time = {
    disabled = false;
    format = "[$time]($style)";
    time_format = "%H:%M";
    style = "subtext1"; # or hex
  };
  character = {
    success_symbol = "[❯](peach)"; # hex: [❯](#fab387)
    error_symbol   = "[❯](red)";
    vimcmd_symbol  = "[❮](cyan)";
  };
};
```

Custom module example
```nix
programs.starship.settings.custom = {
  json = {
    disabled = false;
    symbol = " ";
    style = "bold blue";
    format = "[$symbol]($style)";
    detect_extensions = ["json"];
  };
};
```

TOML equivalents (for reference)
```toml
[git_branch]
symbol = " "
style  = "bold fg:#89b4fa bg:#313244"
format = "on [$symbol$branch]($style) "

[git_status]
style  = "yellow"
format = "[($conflicted$untracked$modified$staged$renamed$deleted)]($style)$ahead_behind$stashed "
stashed = "≡"

[git_state]
style  = "italic red"
format = "([$state( $progress_current/$progress_total)]($style)) "
```

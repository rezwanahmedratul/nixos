# CÓMO: Personalizar Starship (ddubsOS)

Este repositorio gestiona Starship con Home Manager y permite elegir configuraciones:
- Por defecto: `modules/home/cli/starship.nix` (el acento deriva de Stylix)
- Catppuccin: `modules/home/cli/starship-catppuccin.nix` (paleta Catppuccin Mocha completa)

Sección 1 — Elegir la config por host
1) Edita `hosts/<host>/variables.nix`
2) Establece una opción:
```nix
starshipChoice = ../../modules/home/cli/starship.nix;
#starshipChoice = ../../modules/home/cli/starship-catppuccin.nix;
```
3) Aplica: `zcli rebuild` o `nh os switch`

Sección 2 — Colores (referencia rápida)
Los estilos de Starship aceptan nombres (incl. Catppuccin si la paleta está definida) y valores hex, con fg/bg y atributos.
- Ejemplos:
```text
"bold lavender"                # nombre + atributo
"fg:#89b4fa bg:#313244"        # hex explícito fg/bg
"italic red"                   # nombre + atributo
"#a6e3a1"                      # hex (fg)
```

Cambiar colores de Git (ejemplos en Nix)
```nix
programs.starship.settings = {
  git_branch = {
    symbol = " ";
    style = "bold fg:#89b4fa bg:#313244";   # personaliza aquí
    format = "on [$symbol$branch]($style) ";
  };
  git_status = {
    style = "yellow";  # o hex, p.ej. fg:#ffd166
    format = "[($conflicted$untracked$modified$staged$renamed$deleted)]($style)$ahead_behind$stashed ";
    stashed = "≡";
  };
  git_state = {
    style = "italic red";
    format = "([$state( $progress_current/$progress_total)]($style)) ";
  };
};
```

Sobrescribir acento/fondo compartidos (en la config por defecto)
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

Sección 3 — Layout, prompt derecho y símbolos
```nix
programs.starship.settings = {
  format = "$nix_shell$hostname$directory$git_branch$git_state$git_status\n$character";
  right_format = "[$time]($style)";
  time = {
    disabled = false;
    format = "[$time]($style)";
    time_format = "%H:%M";
    style = "subtext1"; # o hex
  };
  character = {
    success_symbol = "[❯](peach)"; # hex: "[❯](#fab387)"
    error_symbol = "[❯](red)";
    vimcmd_symbol = "[❮](cyan)";
  };
};
```

Sección 4 — Módulos personalizados y detección
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

Sección 5 — Usar la paleta Catppuccin
- En `modules/home/cli/starship-catppuccin.nix` se define `palettes.catppuccin_mocha` y se selecciona con:
```nix
palette = lib.mkForce "catppuccin_mocha";
```
- Usa nombres directamente en `style`: `"bold mauve"`, `"peach"`, `"subtext1"`.
- Para añadir colores propios, amplía el attrset `palettes.catppuccin_mocha`.

Sección 6 — Equivalentes TOML (referencia)
```toml
[git_branch]
symbol = " "
style = "bold fg:#89b4fa bg:#313244"
format = "on [$symbol$branch]($style) "

[git_status]
style = "yellow"
format = "[($conflicted$untracked$modified$staged$renamed$deleted)]($style)$ahead_behind$stashed "
stashed = "≡"

[git_state]
style = "italic red"
format = "([$state( $progress_current/$progress_total)]($style)) "
```

Sección 7 — Aplicar y verificar
- Reconstruye: `zcli rebuild` o `nh os switch`
- Recarga la shell o ejecuta `exec zsh`
- Depura:
```bash
starship explain
starship print-config | bat
```

Notas
- `enableZshIntegration = true` está en la config Catppuccin; la config por defecto usa `programs.starship.enable`.
- Si no quieres colores de Stylix, usa hex fijos o la config Catppuccin con nombres.

Referencias
- Configs: `modules/home/cli/starship.nix`, `modules/home/cli/starship-catppuccin.nix`
- Toggle por host: `hosts/<host>/variables.nix` (`starshipChoice`)
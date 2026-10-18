# Home Manager Hyprland Lua Configuration Overview

This guide explains how Home Manager manages and generates a modular Lua-based Hyprland configuration in ZaneyOS (`modules/home/hyprland/`). It is intended as a reference for converting standard Hyprlang or Nix-declared Hyprland configurations into Lua.

---

## High-Level Architecture

The conversion architecture follows a clear pipeline:

1. **Nix State Extraction**: Nix collects variables (theme colors, keyboard layouts, monitor lines, keybindings, environment variables, startup commands).
2. **Nix-to-Lua Serialization**: `lib.generators.toLua { }` serializes the Nix attribute set into a native Lua table string.
3. **Home Manager Lua Module Injection**: Home Manager's `wayland.windowManager.hyprland` module exposes `extraLuaFiles` and `extraConfig`.
4. **Lua Module Execution**: A main entry file (`extraConfig`) uses `require(...)` statements to load individual Lua files, which read the generated global table and configure Hyprland via the `hl.*` Lua runtime API.

```
NixOS / Home Manager Options
       │
       ▼
`zaneyosLuaConfig` (Nix attrset)
       │
       ▼  (lib.generators.toLua)
`ZANEYOS = { ... }` (Global Lua table in "zaneyos.vars")
       │
       ▼
`extraConfig` (`require("zaneyos.settings")`, etc.)
       │
       ▼
`hl.config()`, `hl.bind()`, `hl.env()`, `hl.monitor()` (Hyprland Lua API)
```

---

## File Structure Overview

All files responsible for Hyprland's Lua setup reside in [`modules/home/hyprland/`](../modules/home/hyprland/):

| File | Role |
| :--- | :--- |
| [`modules/home/hyprland/hyprland.nix`](../modules/home/hyprland/hyprland.nix) | Core Home Manager module. Sets `configType = "lua"`, converts Nix data to Lua via `toLua`, and registers `extraLuaFiles` and `extraConfig`. |
| [`modules/home/hyprland/binds.nix`](../modules/home/hyprland/binds.nix) | Nix helper producing keybinding entries (`bindd`, `bindm`). |
| [`modules/home/hyprland/env.nix`](../modules/home/hyprland/env.nix) | Nix helper defining environment variable strings. |
| [`modules/home/hyprland/exec-once.nix`](../modules/home/hyprland/exec-once.nix) | Nix helper defining startup commands (`exec-once`). |
| [`modules/home/hyprland/windowrules.nix`](../modules/home/hyprland/windowrules.nix) | Nix helper holding window rules in Hyprlang/shorthand format. |
| [`modules/home/hyprland/lua/settings.lua`](../modules/home/hyprland/lua/settings.lua) | Lua configuration for general settings, input, decoration, gestures, dwindle, and cursor (`hl.config`). |
| [`modules/home/hyprland/lua/keybinds.lua`](../modules/home/hyprland/lua/keybinds.lua) | Parses keybind strings, normalizes modifiers/chords, maps dispatchers, and registers binds via `hl.bind`. |
| [`modules/home/hyprland/lua/monitors.lua`](../modules/home/hyprland/lua/monitors.lua) | Parses monitor layout lines into specs and calls `hl.monitor`. |
| [`modules/home/hyprland/lua/env.lua`](../modules/home/hyprland/lua/env.lua) | Parses environment variable entries and sets them via `hl.env`. |
| [`modules/home/hyprland/lua/startup.lua`](../modules/home/hyprland/lua/startup.lua) | Handles single-instance execution of startup commands on `hyprland.start`. |
| [`modules/home/hyprland/lua/animations.lua`](../modules/home/hyprland/lua/animations.lua) | Registers beziers and animation rules via `hl.curve` and `hl.animation`. |
| [`modules/home/hyprland/lua/window_rules.lua`](../modules/home/hyprland/lua/window_rules.lua) | Parses and registers window rules via `hl.window_rule`. |

---

## How Home Manager Generates the Lua Config

### 1. Enabling Lua Mode
In [`modules/home/hyprland/hyprland.nix`](../modules/home/hyprland/hyprland.nix:119), `configType` is set to `"lua"`:

```nix
wayland.windowManager.hyprland = {
  configType = "lua";
  enable = true;
  package = pkgs.hyprland;
  ...
};
```

### 2. Converting Nix Data to Lua Table (`lib.generators.toLua`)
Nix options and values are consolidated into a Nix attrset and converted using `lib.generators.toLua { }` ([`hyprland.nix:12`](../modules/home/hyprland/hyprland.nix:12)):

```nix
toLua = lib.generators.toLua { };

zaneyosLuaConfig = {
  modifier = "SUPER";
  keyboard = {
    layout = hyprKbLayout;
    variant = hyprKbVariant;
  };
  theme = {
    base01 = config.lib.stylix.colors.base01;
    base08 = config.lib.stylix.colors.base08;
    base0C = config.lib.stylix.colors.base0C;
  };
  env = envEntries;
  execOnce = execOnceEntries;
  bindd = binddEntries;
  bindm = bindmEntries;
  monitorLines = monitorLines;
  animation = {
    enabled = animationSettings.enabled or true;
    bezier = animationSettings.bezier or [ ];
    animation = animationSettings.animation or [ ];
  };
  windowRulesHyprlang = windowRulesHyprlang;
};
```

### 3. Registering Lua Files via `extraLuaFiles` & Loading via `extraConfig`
The generated table is placed into a virtual module `"zaneyos.vars"`, and other `.lua` files are linked as modules ([`hyprland.nix:130-175`](../modules/home/hyprland/hyprland.nix:130-175)):

```nix
extraConfig = ''
  require("zaneyos.vars")
  require("zaneyos.settings")
  require("zaneyos.monitors")
  require("zaneyos.env")
  require("zaneyos.animations")
  require("zaneyos.window_rules")
  require("zaneyos.startup")
  require("zaneyos.keybinds")
'';
extraLuaFiles = {
  "zaneyos.vars" = {
    autoLoad = false;
    content = ''
      ZANEYOS = ${toLua zaneyosLuaConfig}
    '';
  };
  "zaneyos.settings" = {
    autoLoad = false;
    content = ./lua/settings.lua;
  };
  "zaneyos.monitors" = {
    autoLoad = false;
    content = ./lua/monitors.lua;
  };
  ...
};
```

---

## Consuming the Config in Lua (`hl.*` API)

Inside the Lua files, the global `ZANEYOS` table supplies the state, and Hyprland's `hl` global object provides configuration methods.

### General Settings (`hl.config`)
In [`modules/home/hyprland/lua/settings.lua`](../modules/home/hyprland/lua/settings.lua:1-35):

```lua
local cfg = ZANEYOS or {}
local keyboard = cfg.keyboard or {}
local theme = cfg.theme or {}

hl.config({
  input = {
    kb_layout = keyboard.layout or "us",
    kb_options = "grp:alt_caps_toggle,caps:super",
    numlock_by_default = false,
    repeat_delay = 300,
    follow_mouse = 1,
  },
  general = {
    layout = "dwindle",
    gaps_in = 6,
    gaps_out = 8,
    border_size = 2,
    col = {
      active_border = {
        colors = { "rgba(" .. theme.base08 .. "ff)", "rgba(" .. theme.base0C .. "ff)" },
        angle = 45,
      },
      inactive_border = "rgba(" .. theme.base01 .. "ff)",
    },
  },
})
```

### Environment Variables (`hl.env`)
In [`modules/home/hyprland/lua/env.lua`](../modules/home/hyprland/lua/env.lua:27-32):

```lua
for _, entry in ipairs(env_entries) do
  local key, value = parse_env(entry)
  if key and value then
    hl.env(key, value)
  end
end
```

### Monitor Configuration (`hl.monitor`)
In [`modules/home/hyprland/lua/monitors.lua`](../modules/home/hyprland/lua/monitors.lua:28-33):

```lua
for _, entry in ipairs(monitor_lines) do
  local spec = parse_monitor(entry) -- returns { output = "...", mode = "...", position = "...", scale = "..." }
  if spec then
    hl.monitor(spec)
  end
end
```

### Keybindings & Dispatchers (`hl.bind` & `hl.dispatch`)
In [`modules/home/hyprland/lua/keybinds.lua`](../modules/home/hyprland/lua/keybinds.lua:275-292):

```lua
local function bindd(mods, key, description, dispatcher, args, opts)
  local action
  if dispatcher == "exec" then
    action = function() hl.exec_cmd(args or "") end
  else
    action = dispatch_cmd(dispatcher or "", args or "")
  end

  local bind_opts = opts or {}
  if description and description ~= "" then
    bind_opts.description = description
  end

  hl.bind(chord(mods, key), action, bind_opts)
end
```

---

## Quick Reference for Porting Hyprlang to Lua

| Hyprlang Concept | Lua API Equivalent | Example |
| :--- | :--- | :--- |
| `input { kb_layout = us }` | `hl.config({ input = { kb_layout = "us" } })` | Table hierarchy matches Hyprland sections |
| `env = KEY,VAL` | `hl.env("KEY", "VAL")` | Direct function call |
| `monitor = DP-1, preferred, auto, 1` | `hl.monitor({ output = "DP-1", mode = "preferred", position = "auto", scale = "1" })` | Spec table |
| `bind = SUPER, RETURN, exec, kitty` | `hl.bind("SUPER + RETURN", function() hl.exec_cmd("kitty") end)` | Lua closure or `dispatch` call |
| `windowrule = float, ^(kitty)$` | `hl.window_rule({ float = true, match = { class = "kitty" } })` | Rule spec table |
| `bezier = curve, 0.05, 0.9, 0.1, 1.05` | `hl.curve("curve", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })` | Curve spec table |

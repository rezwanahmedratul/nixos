# A Guide to Customizing Hyprland in ddubsOS

This guide provides a more detailed look at how to customize your Hyprland experience in ddubsOS. We'll go through the most important configuration files, explaining what they do and how you can edit them.

**A Word of Caution:** The configuration files are written in the Nix language. Nix has a very specific syntax, and any mistakes can prevent your system from building successfully. Always be careful when editing these files, and make sure to follow the examples closely.

## Applying Your Changes

After making any changes to these files, you'll need to apply them. Open a terminal and run:

```bash
zcli rebuild
```

This command will rebuild your system with the new configuration. If there are any errors in your configuration, this command will fail.

---

### `binds.nix` - Keybindings

This file controls all of your keyboard and mouse shortcuts in Hyprland.

**Location:** `modules/home/hyprland/binds.nix`

You can change existing keybindings or add new ones. The format is a string with comma-separated values: `MODIFIER, KEY, DISPATCHER, VALUE`.

**Example:**

Let's say you want to change the keybinding for opening a terminal from `SUPER + Return` to `SUPER + T`.

**Original:**

```nix
# ...
    bind = [
      # ...
      "$modifier,Return,exec, ${terminal}"
      # ...
    ];
# ...
```

**Modified:**

```nix
# ...
    bind = [
      # ...
      "$modifier,T,exec, ${terminal}"
      # ...
    ];
# ...
```

---

### `exec-once.nix` - Startup Applications

This file lists the applications and commands that run automatically when you start Hyprland.

**Location:** `modules/home/hyprland/exec-once.nix`

You can add or remove commands from this list. Each command is a string.

**Example:**

If you want to start the `copyq` application every time you log in, you can add it to the list.

**Original:**

```nix
# ...
    exec-once = [
      # ...
    ];
# ...
```

**Modified:**

```nix
# ...
    exec-once = [
      # ...
      "copyq"
    ];
# ...
```

---

### `decoration.nix` - Window Decorations

This file controls the appearance of window borders, shadows, and blur effects.

**Location:** `modules/home/hyprland/decoration.nix`

You can change values like `rounding` for rounded corners, or adjust the `blur` and `shadow` settings.

**Example:**

To increase the rounding of window corners from `0` to `10`.

**Original:**

```nix
# ...
      decoration = {
        rounding = 0;
# ...
```

**Modified:**

```nix
# ...
      decoration = {
        rounding = 10;
# ...
```

---

### `env.nix` - Environment Variables

This file sets environment variables for your Hyprland session. These can affect how applications behave.

**Location:** `modules/home/hyprland/env.nix`

You can add or change environment variables in this list.

**Example:**

To set the `MOZ_ENABLE_WAYLAND` variable to `1`, which forces Firefox to run in Wayland mode.

**Original:**

```nix
# ...
    env = [
      # ...
      "SDL_VIDEODRIVER, wayland"
      # ...
    ];
# ...
```

**Modified:**

```nix
# ...
    env = [
      # ...
      "SDL_VIDEODRIVER, wayland"
      "MOZ_ENABLE_WAYLAND, 1"
      # ...
    ];
# ...
```

---

### `gestures.nix` - Touchpad Gestures

This file controls touchpad gestures, like swiping between workspaces.

**Location:** `modules/home/hyprland/gestures.nix`

You can enable or disable gestures and change their behavior.

**Example:**

To disable workspace swiping.

**Original:**

```nix
# ...
      gestures = {
        workspace_swipe = 1;
# ...
```

**Modified:**

```nix
# ...
      gestures = {
        workspace_swipe = 0;
# ...
```

---

### `misc.nix` - Miscellaneous Settings

This file contains various settings that don't fit into the other categories.

**Location:** `modules/home/hyprland/misc.nix`

You can change settings like `vrr` (Variable Refresh Rate) or `disable_hyprland_logo`.

**Example:**

To enable Variable Refresh Rate.

**Original:**

```nix
# ...
      misc = {
        # ...
        vrr = 0;
        # ...
      };
# ...
```

**Modified:**

```nix
# ...
      misc = {
        # ...
        vrr = 1;
        # ...
      };
# ...
```

---

### `hyprland.nix` - Main Configuration

This is the main Hyprland configuration file. It sets up general settings, input devices, and the window layout.

**Location:** `modules/home/hyprland/hyprland.nix`

You can change things like the keyboard layout, touchpad settings, and the layout engine.

**Example:**

To change the keyboard layout from the default to `us`.

**Original:**

```nix
# ...
      input = {
        kb_layout = "${keyboardLayout}";
# ...
```

**Modified:**

```nix
# ...
      input = {
        kb_layout = "us";
# ...
```

---

### `windowrules.nix` - Window Rules

This file defines rules for how specific windows should behave. You can make certain applications always float, open on a specific workspace, or have a certain opacity.

**Location:** `modules/home/hyprland/windowrules.nix`

You can add new rules to the `windowrule` list.

**Example:**

To make the `thunar` file manager always float.

**Original:**

```nix
# ...
      windowrule = [
        # ...
        "float, class:^(foot-floating)$"
        # ...
      ];
# ...
```

**Modified:**

```nix
# ...
      windowrule = [
        # ...
        "float, class:^(foot-floating)$"
        "float, class:^(Thunar)$"
        # ...
      ];
# ...
```

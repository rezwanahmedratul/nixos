# Outline: Hyprland monitorv2 and optional way-displays integration for ddubsos

## Context
- ddubsos currently configures Hyprland displays via a per-host string variable extraMonitorSettings injected into wayland.windowManager.hyprland.extraConfig.
- Hyprland now supports monitorv2 blocks, which are more structured than legacy `monitor =` lines.
- way-displays is a daemon for wlroots compositors (e.g., Sway) that automatically manages outputs. Upstream explicitly states: “Hyprland already provides all the features of way-displays … it is explicitly not supported.”

## Goals
- Provide a more seamless, typed way to configure displays per host in ddubsos using Hyprland’s monitorv2.
- Maintain strict backward compatibility: existing hosts using extraMonitorSettings must continue to work unchanged.
- Optionally support way-displays for non-Hyprland wlroots compositors (e.g., Sway) on a per-host basis.

## Decisions
- Hyprland
  - Do NOT use way-displays with Hyprland (unsupported upstream; redundant).
  - Introduce two new optional host variables for structure:
    - hyprMonitorsV2: list of attribute sets rendered to monitorv2 blocks.
    - hyprMonitors: list of attribute sets rendered to legacy `monitor =` lines.
  - Fallback order for monitor configuration (highest precedence first):
    1) hyprMonitorsV2 (if non-empty)
    2) hyprMonitors (if non-empty)
    3) extraMonitorSettings (existing string)
- Sway (optional)
  - Allow an opt-in toggle to run way-displays as a user service on hosts that enable Sway.
  - Keep Hyprland untouched by way-displays.

## Proposed schema
- monitorv2 example (native Hyprland syntax):

```nix
# Stored as structured host variable, rendered by the module
hyprMonitorsV2 = [
  {
    output = "DP-1";
    mode = "1920x1080@144";
    position = "0x0";
    scale = 1;
    # transform controls rotation/flip using wl_output_transform:
    #   0=normal, 1=90, 2=180, 3=270, 4=flipped, 5=flipped-90, 6=flipped-180, 7=flipped-270
    transform = 2;
    enabled = true; # set false to disable this output
    # Optional keys: vrr = "on"; mirror = "HDMI-A-1";
  }
];
```

- Legacy `monitor =` example (structured form rendered by the module):

```nix
hyprMonitors = [
  {
    name = "Virtual-1";     # alias: output
    mode = "1920x1080@60";  # or "preferred" / "highest"
    position = "auto";      # e.g., "0x0" or "auto"
    scale = 1;               # number or string
    enabled = true;          # when false, would render as: monitor = Virtual-1, disable
  }
  {
    name = "HDMI-A-1";
    mode = "1920x1080@60";
    position = "1920x0";    # right of the first monitor
    scale = 1;
    enabled = true;
  }
];
```

- Backward compatible string (as today):

```nix
extraMonitorSettings = ''
  monitor = Virtual-1, 1920x1080@60,auto,1
'';
```

### Transform values (Hyprland / wl_output_transform)
- 0 = normal
- 1 = 90 degrees (clockwise)
- 2 = 180 degrees
- 3 = 270 degrees (clockwise)
- 4 = flipped (horizontal mirror)
- 5 = flipped-90
- 6 = flipped-180
- 7 = flipped-270

### Additional examples: Multiple monitors (monitorv2)
```nix
# Side-by-side dual monitors, with one disabled internal panel
hyprMonitorsV2 = [
  {
    output = "DP-1";
    mode = "2560x1440@144";
    position = "0x0";  # primary left
    scale = 1;
    transform = 0;
    enabled = true;
  }
  {
    output = "HDMI-A-1";
    mode = "1920x1080@60";
    position = "2560x0"; # placed to the right of DP-1
    scale = 1.25;
    transform = 0;
    enabled = true;
  }
  {
    output = "eDP-1";    # laptop internal panel
    mode = "1920x1080@60";
    position = "auto";
    scale = 1;
    transform = 0;
    enabled = false;      # explicitly disabled
  }
];
```

```nix
# Vertical stack (one above the other)
hyprMonitorsV2 = [
  {
    output = "DP-1";
    mode = "3440x1440@100";
    position = "0x0";      # bottom monitor
    scale = 1;
    transform = 0;
    enabled = true;
  }
  {
    output = "HDMI-A-1";
    mode = "1920x1080@60";
    position = "0x1440";   # stacked above (y starts at 1440)
    scale = 1;
    transform = 1;          # rotated 90 degrees
    enabled = true;
  }
];
```

```nix
# Mirroring an external display from the internal panel
ehyprMonitorsV2 = [
  {
    output = "eDP-1";
    mode = "1920x1080@60";
    position = "0x0";
    scale = 1;
    enabled = true;
  }
  {
    output = "HDMI-A-1";
    mirror = "eDP-1";  # mirror this output
    enabled = true;
  }
];
```

## Implementation plan

### 1) Update modules/home/hyprland/hyprland.nix
- Import host variables as an attrset vars = import ../../../hosts/${host}/variables.nix.
- Read keyboardLayout, extraMonitorSettings, hyprMonitorsV2, hyprMonitors with defaults.
- Add lib to function args.
- Build monitorsText by rendering in precedence order:
  - If hyprMonitorsV2 != [], map over items to generate monitorv2 blocks.
  - Else if hyprMonitors != [], map to legacy `monitor =` lines.
  - Else use extraMonitorSettings.
- Set wayland.windowManager.hyprland.extraConfig = monitorsText.

Notes
- Rendering rules:
  - monitorv2: output ordered keys first [output, mode, position, scale, transform] then any extra provided keys; skip nulls.
  - legacy: name/output, mode (default "preferred"), position (default "auto"), scale (default 1).
- Do not break or remove existing extraMonitorSettings usage.

### 2) Document examples in hosts/default/variables.nix
- Keep existing extraMonitorSettings example.
- Add commented examples for hyprMonitorsV2 and hyprMonitors to guide migration.

### 3) Optional: way-displays for Sway
- Add a new module (e.g., modules/home/sway/way-displays.nix) to:
  - Install pkgs.way-displays.
  - Add a systemd --user service (WantedBy=graphical-session.target) to run way-displays.
  - Optionally generate a config file from a host variable (e.g., swayDisplays or reuse a shared schema in the future).
- Expose per-host toggle(s):
  - useWayDisplaysForSway = true;
- Important: Ensure this service does NOT start on Hyprland sessions.

## Files to be modified/added
- Modify: modules/home/hyprland/hyprland.nix
  - Add lib argument; import vars; render monitorsText; set extraConfig = monitorsText.
- Modify: hosts/default/variables.nix
  - Add commented examples for hyprMonitorsV2 and hyprMonitors.
- Add (optional, only if adopting way-displays for Sway):
  - modules/home/sway/way-displays.nix (new user service + optional config generation)
  - Potential host variables: useWayDisplaysForSway, swayDisplays (schema TBD)

## Backward compatibility (paramount)
- No breaking changes:
  - If neither hyprMonitorsV2 nor hyprMonitors is defined, behavior remains identical to today via extraMonitorSettings.
  - Existing hosts need zero edits.
- Safe migration path:
  - Hosts can gradually add hyprMonitorsV2 (or hyprMonitors) and remove extraMonitorSettings later.
  - Fallback precedence ensures a host can keep both during transition.

## Pros / Cons

Pros
- Stronger typing and clarity with monitorv2; easier to reason about per-host monitor state.
- Preserves current behavior by default; zero-cost adoption.
- Easy to extend with optional keys (vrr, transform, mirror, enable/disable).
- Provides a clean bridge to optional way-displays for Sway where it shines.

Cons
- Slightly more module logic; small maintenance surface.
- monitorv2 requires a sufficiently recent Hyprland (most users already are).
- Two structured paths (V2 and legacy) plus raw string increases conceptual surface area during migration.

## Validation & testing
- Hyprland
  - nixos-rebuild switch or home-manager switch (depending on your setup) and restart your session.
  - Inspect generated config from Hyprland logs; run `hyprctl monitors` to confirm mode/scale/position.
  - Validate transform/VRR keys if used.
- Sway (optional way-displays)
  - Enable the user service, log in to a Sway session.
  - Check `systemctl --user status way-displays.service`.
  - Test hotplugging; verify arrangements are applied.
  - Disable on issues or when using Hyprland.

## Migration guide
- Do nothing: keep extraMonitorSettings; you’re backward compatible.
- Move to hyprMonitorsV2:
  1. Copy your current monitor lines into structured objects.
  2. Add hyprMonitorsV2 = [ { output = …; mode = …; position = …; scale = …; } … ];
  3. Rebuild; verify; remove extraMonitorSettings when satisfied.
- Optional: If you use Sway on a host, consider enabling way-displays there.

## Notes on way-displays packaging
- Nixpkgs provides way-displays (see pkgs/by-name/wa/way-displays/package.nix).
- Add to home.packages or environment.systemPackages when enabling for Sway.
- Refer to upstream wiki for configuration details and advanced recipes; avoid using it under Hyprland.

## Future improvements
- Define a shared display schema once and generate:
  - Hyprland monitorv2 blocks
  - Legacy hyprland `monitor =` lines
  - way-displays config (for Sway)
- Add a simple validation step (e.g., assert known keys, ensure mode strings match NxM@Hz).
- Provide utility per-host helpers to quickly toggle a monitor or switch a primary display.


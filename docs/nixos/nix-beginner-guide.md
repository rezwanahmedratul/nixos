# Welcome to ddubsOS! A Beginner's Guide to Customization

Welcome! This guide is for users who are new to Nix and want to make some common customizations to their ddubsOS setup. We'll keep it simple and focus on the essentials.

## Understanding the Layout

NixOS configurations can seem complex, but for day-to-day changes, you only need to know about a few key files and directories.

-   `flake.nix`: This is the main file for the entire system. You shouldn't need to edit this file directly for most common changes.
-   `hosts/`: This directory contains the configuration for each individual computer (or "host") you've installed ddubsOS on.
    -   `hosts/<your-hostname>/`: This is where you'll make most of your changes.
        -   `variables.nix`: This is your main control panel. You can enable/disable features, change settings, and more.
        -   `host-packages.nix`: This is where you can add packages that you only want on this specific computer.
-   `modules/`: This directory contains the bulk of the configuration, broken down into smaller, reusable pieces ("modules").
    -   `modules/core/global-packages.nix`: You can add packages here if you want them to be installed on *all* of your ddubsOS computers.
    -   `modules/home/hyprland/binds.nix`: This is where you can customize your Hyprland keybindings.

## How to Add Packages

There are two main ways to add packages:

### 1. For a Single Computer

If you only want to install a package on your current computer, you'll add it to `hosts/<your-hostname>/host-packages.nix`.

1.  Open `hosts/<your-hostname>/host-packages.nix` in your favorite editor.
2.  You'll see a list of packages. Simply add the name of the package you want to install to the list. For example, to add the `cowsay` package, you would change this:

    ```nix
    [
      brave
      (catppuccin-vsc.override {
        variant = "mocha";
      })
    ]
    ```

    to this:

    ```nix
    [
      brave
      (catppuccin-vsc.override {
        variant = "mocha";
      })
      cowsay
    ]
    ```

3.  Save the file.

### 2. For All Computers

If you want a package to be installed on every computer you use ddubsOS on, you'll add it to `modules/core/global-packages.nix`. The process is the same as above.

## How to Change Monitor Settings

You can change your monitor settings in `hosts/<your-hostname>/variables.nix`.

1.  Open `hosts/<your-hostname>/variables.nix`.
2.  Look for the `extraMonitorSettings` line.
3.  You can add your monitor settings here. For example, to set the resolution and refresh rate for a monitor named `DP-1`, you would change this:

    ```nix
    extraMonitorSettings = "";
    ```

    to this:

    ```nix
    extraMonitorSettings = "monitor=DP-1,1920x1080@144";
    ```

4.  Save the file.

## How to Change Hyprland Bindings

You can change your Hyprland keybindings in `modules/home/hyprland/binds.nix`.

1.  Open `modules/home/hyprland/binds.nix`.
2.  You'll see a list of keybindings. You can change them to your liking. For example, to change the keybinding for opening a terminal from `SUPER, Return` to `SUPER, T`, you would change this:

    ```nix
    "SUPER, Return, exec, ${terminal}"
    ```

    to this:

    ```nix
    "SUPER, T, exec, ${terminal}"
    ```

3.  Save the file.

## Applying Your Changes

After you've made any changes, you need to apply them.

1.  Open a terminal.
2.  Run the command `zcli rebuild`. This will apply your changes to the system.
3.  If the command completes successfully, your changes are now active! Some changes may require a reboot to take effect.

[English](README.md) | [Español](README.es.md)

<div align="center">

## ZaneyOS 🟰 Best ❄️ NixOS Configs

\*\* Updated: August 7th, 2026

| Note: As of release v2.6.4+ Hyprland config files are in LUA format

ZaneyOS is a simple way of reproducing my configuration on any NixOS system.
This includes the wallpaper, scripts, applications, config files, and more.

## Important Note on Noctalia

> The first time you login, screen will be blank SUPER + SHIFT + C to exit.
> Login in, noctalia will start from then on

## 🌸 Ryoku Desktop (Quickshell) Integration

The `ryoku` branch introduces declarative integration for the [Ryoku-on-NixOS](https://github.com/Ryoku-dev/Ryoku-on-NixOS) desktop shell, built with Quickshell, Qt6/QML, Matugen, and a Go IPC daemon (`ryoku-shell`):
- **Karuma Floating Bar**: Live hardware metrics, workspaces, network, battery, and media status.
- **Ryoku App Launcher & Quick Settings**: Instantaneous, keyboard-driven launcher and control center.
- **Ryogami Dynamic Theming**: Material You accent palette generation from wallpapers via Matugen.
- **Workspace Expo / Overview**: Full-screen live preview tiles and interactive workspace organization.
- **Ryoku Spring Animations**: High-fidelity cubic bezier curves (`ryokuBloom`, `ryokuSettle`).
- **Ryoku Hub & Stage Editor**: Built-in visual settings and widget customization.

<img align="center" width="80%" src="img/ZaneyOS-Floating.png" />

</div>

<details>
<summary><strong>📸 More Screenshots</strong></summary>

### Waybar Themes

<img align="center" width="80%" src="img/demo-img2.png" />

<img align="center" width="80%" src="img/demo-img3.png" />

### Noctalia Shell Integration

<img align="center" width="80%" src="img/ZaneyOS-noctalia-panel.png" />

<img align="center" width="80%" src="img/ZaneyOS-noctalia-app.png" />

<img align="center" width="80%" src="img/ZaneyOS-noctalia-settings.png" />

<img align="center" width="80%" src="img/ZaneyOS-noctalia-weather.png" />

### Additional Features

<img align="center" width="80%" src="img/ZaneyOS-keybind-search.png" />

<img align="center" width="80%" src="img/ZaneyOS-nivim-emacs.png" />

</details>

<div align="center">

### Cheatsheets and Guides

- Nix Beginner Guide: [English](cheatsheets/nix-beginner-guide.md) |
  [Español](cheatsheets/nix-beginner-guide.es.md)
- Hyprland Customization Guide:
  [English](cheatsheets/hyprland-customization-guide.md) |
  [Español](cheatsheets/hyprland-customization-guide.es.md)

#### 🍖 Requirements

- You must be running on NixOS, version 24.05+.
- The `zaneyos` folder (this repo) is expected to be in your home directory.
- You must have installed NIXOS using **GPT** parition with booting with
  **UEFI**.
- ** 500MB minimum /boot partition required. **
- Systemd-boot is what is supported.
- For GRUB you will have to brave the internet for a how-to. ☺️
- Manually editing your host specific files.
- The host is the specific computer your installing on.

#### 🎹 Pipewire & Notification Menu Controls

- We are using the latest and greatest audio solution for Linux. Not to mention
  you will have media and volume controls in the notification center available
  in the top bar.

#### 🏇 Optimized Workflow & Simple Yet Elegant Neovim

- Using Hyprland for increased elegance, functionality, and efficiency.
- No massive NeoVIM project here, using `nixvim` for an
  incredible NeoVIM setup. With language support already added in.

#### 🖥️ Multi Host & User Configuration

- You can define separate settings for different host machines and users.
- Easily specify extra packages for your users in the `modules/core/user.nix`
  file.
- Easy to understand file structure and simple, but encompassing, configuration.

#### 🎛️ Declarative Desktop Shell Selection

- Switch between three complete desktop shells in `hosts/<hostname>/variables.nix`:
  - `"ryoku"`: [Ryoku Desktop](https://github.com/Ryoku-dev/Ryoku-on-NixOS) — Quickshell, Karuma bar, Matugen-powered Ryogami dynamic wallpaper theming, app launcher, control center, and spring bezier animations.
  - `"noctalia"`: Noctalia Quickshell suite — floating quicksettings, launcher, and system panels.
  - `"waybar"`: Classic Waybar — highly customizable modular status bar with SwayNC and Rofi.
- Match animation curves with `animChoice` (e.g. `../../modules/home/hyprland/animations-ryoku.nix`).


#### 👼 An Incredible Community Focused On Support

- The entire idea of ZaneyOS is to make NixOS an approachable space.
- NixOS is actually a great community that you will want to be a part of.
- Many people who are patient and happy to spend their free time helping you are
  running ZaneyOS.
- Feel free to reach out on the Discord for any help with anything.

#### 📦 How To Install Packages?

- You can search the [Nix Packages](https://search.nixos.org/packages?) &
  [Options](https://search.nixos.org/options?) pages for what a package may be
  named or if it has options available that take care of configuration hurdles
  you may face.
- To add a package there are the sections for it in `modules/core/packages.nix`
  and `modules/core/user.nix`. One is for programs available system wide and the
  other for your users environment only.

#### 🙋 Having Issues / Questions?

- Please feel free to raise an issue on the repo, please label a feature request
  with the title beginning with [feature request], thank you!
- Contact us on [Discord](https://discord.gg/XhZmNTnhtp) as well, for a potentially
  faster response.

# Hyprland Keybindings

Below are the keybindings for Hyprland. Common window management and workspace navigation shortcuts work across all modes, while desktop shell keybindings adapt based on `barChoice` in `hosts/<hostname>/variables.nix`.

### 🌸 Ryoku Shell Keybindings (`barChoice = "ryoku"`)

| Keybinding | Action | Command / Target |
| :--- | :--- | :--- |
| `$modifier + Space` / `Alt + Space` | **App Launcher** | Toggle Ryoku quick application launcher |
| `$modifier + Escape` | **Quick Settings & Control Center** | Toggle network, volume, brightness, and status controls |
| `$modifier + Tab` | **Workspace Overview** | Expo view with interactive live window previews |
| `$modifier + V` | **Clipboard History** | Toggle Ryoku clipboard manager |
| `$modifier + M` | **Audio Visualizer** | Toggle Ryoku desktop visualizer |
| `$modifier + W` | **Wallpaper Picker** | Open Ryogami interactive wallpaper selector |
| `$modifier + Shift + W` | **Random Wallpaper** | Instantly pick and apply random wallpaper with Matugen theming |
| `$modifier + L` | **Lock Screen** | Lock session via `ryoku-qylock` |
| `$modifier + ,` | **Ryoku Hub** | Open system settings and visual customization hub |
| `$modifier + Shift + D` | **Stage Editor** | Open desktop widget and panel layout editor |
| `$modifier + Shift + S` | **Region Screenshot** | Capture custom screen region via `ryoku-cmd-ryoshot` |
| `$modifier + K` | **Keybinds Cheat Sheet** | Quickshell overlay with interactive hotkey search |

---

### 🎨 Noctalia Shell Keybindings (`barChoice = "noctalia"`)

| Keybinding | Action |
| :--- | :--- |
| `Alt + Space` / `$modifier + Shift + Return` | Noctalia Launcher Toggle |
| `$modifier + M` | Notifications Menu |
| `$modifier + Ctrl + V` | Clipboard Manager |
| `$modifier + Alt + P` / `$modifier + Shift + ,` | Settings Panel |
| `$modifier + L` | Lock Screen |
| `$modifier + Shift + W` | Wallpaper Manager |
| `$modifier + P` | Power Menu |
| `$modifier + C` | Control Center |
| `$modifier + Alt + S` | Region Screenshot |

---

### 📊 Waybar Mode Keybindings (`barChoice = "waybar"`)

| Keybinding | Action |
| :--- | :--- |
| `$modifier + D` / `$modifier + Shift + Return` | Launch Rofi Application Launcher |
| `$modifier + V` | Clipboard History via `cliphist` |
| `$modifier + Shift + W` | Wallpaper Setter |
| `$modifier + Shift + N` | Restart SwayNC Notification Daemon |

---

### 🪟 General Window & Workspace Management

| Keybinding | Action |
| :--- | :--- |
| `$modifier + Return` | Launch default terminal (`alacritty` / `kitty`) |
| `$modifier + B` | Launch default web browser |
| `$modifier + F` | Launch GUI file manager (Nautilus) |
| `$modifier + Y` | Open terminal file manager (`yazi`) |
| `$modifier + X` | Kill active window |
| `$modifier + Shift + F` | Toggle window fullscreen |
| `$modifier + P` | Toggle pseudo tiling |
| `$modifier + Shift + I` | Toggle layout split |
| `$modifier + 1-10` | Switch to workspace 1–10 |
| `$modifier + Shift + 1-10` | Move active window to workspace 1–10 |
| `Alt + Tab` | Cycle to next window / Bring active to top |
| `$modifier + Shift + C` | Exit Hyprland |


## Installation:

> **⚠️ IMPORTANT:** These installation methods are for **NEW INSTALLATIONS
> ONLY**. If you already have ZaneyOS installed and want to upgrade to v2.4, see
> the [Upgrade Instructions](#upgrading-from-zaneyos-23-to-24) below. Note:
> There is an issue with upgrade script. It's been removed until it's fixed.

<details>
<summary><strong> ⬇️ Install with script (NEW INSTALLATIONS ONLY)</strong></summary>

### 📜 Script:

This is the easiest and recommended way of starting out for **new
installations**. The script is not meant to allow you to change every option
that you can in the flake or help you install extra packages. It is simply here
so you can get my configuration installed with as little chances of breakages
and then fiddle to your hearts content!

> **⚠️ WARNING:** This script will completely replace any existing ~/zaneyos
> directory. Do NOT use this if you already have ZaneyOS installed and
> configured.

Simply copy this and run it:

![ZaneyOS First Install Command](img/first-install-cmd.jpg)

```
nix-shell -p git curl pciutils
```

Then:

![ZaneyOS Install Script Command](img/install-script.jpg)

```
sh <(curl -L https://gitlab.com/rezwanahmedratul/nixos/-/raw/main/install-nixos.sh)
```

#### The install process will look something like this:

![First Part Of Install](img/1.jpg)

![Second Part Of Install](img/2.jpg)

#### After the install completes your environment will probably look broken. Just reboot and you will see this as your login:

![Display Manager](img/3.jpg)

#### Then after login you should see a screen like this:

![Desktop Example](img/4.jpg)

</details>

<details>
<summary><strong> 🦽 Manual install process:  </strong></summary>

1. Run this command to ensure Git & Vim are installed:

```
nix-shell -p git vim
```

2. Clone this repo & enter it:

```
cd && git clone https://gitlab.com/rezwanahmedratul/nixos.git -b main ~/nixos
cd nixos

You can still run the `install.sh` script if you want to.
```

- _You should stay in this folder for the rest of the install_

3. Create the host folder for your machine(s) like so:

```
cp -r hosts/default hosts/<your-desired-hostname>
git add .
```

4. Edit `hosts/<your-desired-hostname>/variables.nix`
   `nixos-generate-config --show-hardware-config > hosts/<your-desired-hostname>/hardware.nix`

```

7. Run this to enable flakes and install the flake replacing hostname with
   profile. I.e. `intel`, `nvidia`, `nvidia-laptop`, `amd-hybrid`, or `vm`

```

NIX_CONFIG="experimental-features = nix-command flakes"
sudo nixos-rebuild switch --flake .#profile

```

Now when you want to rebuild the configuration you have access to an alias
called `fr` that will rebuild the flake and you do not have to be in the
`zaneyos` folder for it to work.

### Special Recognitions:

Thank you for all your assistance

- KoolDots  https://github.com/LinuxBeginnings
- JakKoolit  https://github.com/Jakoolit
- Justaguylinux https://codeberg.org/Justaguylinux
- Jerry Starke https://github.com/JerrySM64

## Hope you enjoy!
```

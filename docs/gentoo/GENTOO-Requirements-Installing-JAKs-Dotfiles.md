# Gentoo Hyprland Setup Guide for JaKooLit's Configuration

**Authored by Don Williams (ddubs)**

This guide provides a comprehensive package comparison between Arch Linux (JaKooLit's scripts) and Gentoo Linux, with specific instructions for new Gentoo users wanting to install Hyprland with JaKooLit's dotfiles.

## 📚 Essential Reading Before Starting

### Official Documentation:
- **Gentoo Handbook**: https://wiki.gentoo.org/wiki/Handbook:Main_Page
- **Gentoo Hyprland Wiki**: https://wiki.gentoo.org/wiki/Hyprland
- **Hyprland Official Wiki**: https://wiki.hyprland.org/
- **JaKooLit's Hyprland Dotfiles**: https://github.com/JaKooLit/Hyprland-Dots

### Important Gentoo Concepts:
- **Portage**: Gentoo's package manager (equivalent to pacman on Arch)
- **USE Flags**: Control what features are compiled into packages
- **Overlays**: Third-party package repositories (guru overlay is needed for some packages)
- **emerge**: Command to install packages (equivalent to `pacman -S`)
- **eix**: Fast package search tool (recommended to install first)

## ⚠️ Important Precautions

### 1. **Important Considerations**
Support for current Jak's Hyprland dotfiles requires Hyprland and supporting applications to be from the Gentoo testing branch. Current stable branch only has Hyprland v0.49, which will result in many Hyprland errors if used.

```bash
# To enable testing branch packages, add to /etc/portage/package.accept_keywords
echo 'gui-wm/hyprland ~amd64' | sudo tee -a /etc/portage/package.accept_keywords/hyprland
# Repeat for other Hyprland-related packages as needed
```

### 2. **Enable the GURU Overlay**
Many Hyprland-related packages are in the guru overlay:
```bash
sudo emerge --ask app-eselect/eselect-repository
sudo eselect repository enable guru
sudo emerge --sync guru
```

### 3. **USE Flag Configuration**
Hyprland requires specific USE flags. The emerge commands will prompt you with `--autounmask-write` when needed. Always review changes before applying:
```bash
# After --autounmask-write, apply changes with:
sudo etc-update --automode -5  # Auto-merge all changes
# OR for manual review:
sudo dispatch-conf
```

### 4. **System Requirements**
- **Graphics**: Ensure your GPU supports Wayland (AMD/Intel recommended, NVIDIA requires extra setup)
- **Kernel**: Modern kernel with DRM support
- **systemd**: These instructions assume systemd (not OpenRC)

### 5. **Compilation Time**
Gentoo compiles packages from source. Large packages like webkit-gtk can take significant time.

### 6. **Install eix First**
Makes package searching much faster:
```bash
sudo emerge -v app-portage/eix
sudo eix-update
```

## Application Requirements Based on Jak's Arch-Install Script

### Base Packages (00-base.sh)
- base-devel
- archlinux-keyring
- findutils

### Core Hyprland Packages (01-hypr-pkgs.sh)
**Essential (hypr_package):**
- bc ✓ (installed: sys-devel/bc)
- cliphist ✓ (available: gui-apps/cliphist)
- curl ✓ (installed: net-misc/curl)
- grim ✓ (available: gui-apps/grim)
- gvfs ✓ (available: gnome-base/gvfs)
- gvfs-mtp ✓ (included in gnome-base/gvfs with mtp USE flag)
- hyprpolkitagent (any Hyprland polkit works, e.g., gnome-extra/polkit-gnome)
- imagemagick ✓ (available: media-gfx/imagemagick)
- inxi ✓ (available: sys-apps/inxi)
- jq ✓ (installed: app-misc/jq)
- kitty ✓ (installed: x11-terms/kitty)
- kvantum ✗
- libspng ✓ (installed: media-libs/libspng)
- nano ✓ (available: app-editors/nano)
- network-manager-applet ✓ (available: gnome-extra/nm-applet)
- pamixer ✓ (available: media-sound/pamixer)
- pavucontrol ✓ (available: media-sound/pavucontrol)
- playerctl ✓ (available: media-sound/playerctl)
- python-requests ✓ (installed: dev-python/requests)
- python-pyquery ✓ (available: dev-python/pyquery)
- qt5ct ✓ (available: x11-misc/qt5ct)
- qt6ct ✗ (not available in Gentoo)
- qt6-svg ✓ (installed: dev-qt/qtsvg)
- rofi ✓ (installed: x11-misc/rofi)
- slurp ✓ (available: gui-apps/slurp)
- swappy ✓ (available: gui-apps/swappy)
- swaync ✓ (available: gui-apps/swaync)
- awww ✓ (available: gui-apps/awww)
- unzip ✓ (installed: app-arch/unzip)
- wallust ✓ (available in guru overlay - x11-misc/wallust)
- waybar ✓ (installed: gui-apps/waybar)
- wget ✓ (installed: net-misc/wget)
- wl-clipboard ✓ (available: gui-apps/wl-clipboard)
- wlogout ✓ (available: gui-apps/wlogout)
- xdg-user-dirs ✓ (available: x11-misc/xdg-user-dirs)
- xdg-utils ✓ (installed: x11-misc/xdg-utils)
- yad ✓ (available in guru overlay - gnome-extra/yad) **REQUIRED for help dialogs**

**Optional (hypr_package_2):**
- brightnessctl ✓ (available: app-misc/brightnessctl)
- btop ✓ (installed: sys-process/btop)
- cava ✓ (available: media-sound/cava)
- loupe ✓ (available: media-gfx/loupe)
- fastfetch ✓ (installed: app-misc/fastfetch)
- gnome-system-monitor ✓ (available: gnome-extra/gnome-system-monitor)
- mousepad ✓ (available: app-editors/mousepad)
- mpv ✓ (available: media-video/mpv)
- mpv-mpris (built-in with mpv in Gentoo)
- nvtop ✓ (available: sys-process/nvtop)
- nwg-look ✓ (installed: app-misc/nwg-look)
- nwg-displays ✓ (available: gui-apps/nwg-displays)
- pacman-contrib ✗ (Arch-specific)
- qalculate-gtk ✓ (available: sci-calculators/qalculate-gtk)
- yt-dlp ✓ (available: net-misc/yt-dlp)

### Hyprland Core (hyprland.sh)
- hyprland ✓ (installed: gui-wm/hyprland)
- hypridle ✓ (installed: gui-apps/hypridle)
- hyprlock ✓ (installed: gui-apps/hyprlock)

### Pipewire (pipewire.sh)
- pipewire ✓ (installed: media-video/pipewire)
- wireplumber ✓ (installed: media-video/wireplumber)
- pipewire-audio ✓ (part of media-video/pipewire)
- pipewire-alsa ✓ (part of media-video/pipewire)
- pipewire-pulse ✓ (part of media-video/pipewire)
- sof-firmware ✓ (installed: sys-firmware/sof-firmware)

### Fonts (fonts.sh)
- adobe-source-code-pro-fonts ✗
- noto-fonts-emoji ✗
- otf-font-awesome ✗ (similar: media-fonts/fontawesome)
- ttf-droid ✗
- ttf-fira-code ✓ (installed: media-fonts/fira-code)
- ttf-fantasque-nerd ✗
- ttf-jetbrains-mono ✓ (installed: media-fonts/jetbrains-mono)
- ttf-jetbrains-mono-nerd ✗
- ttf-victor-mono ✗
- noto-fonts ✗

### GTK Themes (gtk_themes.sh)
- unzip ✓ (installed: app-arch/unzip)
- gtk-engine-murrine ✗

### Battery Monitor (battery-monitor.sh)
- acpi ✗
- libnotify ✗

## Summary Statistics

**Available for Installation:** 38/40 packages from priority list
**Success Rate:** ~95%
**Packages Requiring Alternatives:** 2 (cliphist→clipman, hyprpolkitagent→polkit-gnome)

## Critical Missing Packages for Full Functionality

### High Priority:
1. **Screenshot/Screen Capture:**
   - grim (Wayland screenshot tool)
   - slurp (Wayland screen area selector)
   - swappy (screenshot editor)
   - hyprshot (Hyprland screenshot utility)

2. **Clipboard Management:**
   - cliphist (clipboard history)
   - wl-clipboard (Wayland clipboard utilities)

3. **Notifications:**
   - swaync (notification daemon)
   - libnotify (for battery monitor)

4. **Wallpaper:**
   - awww (animated wallpaper)
   - wallust (color palette generator)

5. **Audio:**
   - pamixer (PulseAudio/PipeWire mixer)
   - pavucontrol (PulseAudio volume control)
   - playerctl (media player control)

6. **Brightness:**
   - brightnessctl (laptop brightness control)

7. **Polkit:**
   - hyprpolkitagent (authentication agent for Hyprland)

8. **File Management:**
   - gvfs (virtual file system)
   - gvfs-mtp (MTP device support)

9. **System Tools:**
   - imagemagick (image manipulation)
   - inxi (system information)
   - nano (text editor - or use vim/neovim)

10. **Session Management:**
    - wlogout (logout menu)
    - xdg-user-dirs (user directory management)

11. **Qt Theming:**
    - qt5ct (Qt5 configuration)
    - qt6ct (Qt6 configuration)
    - kvantum (Qt theme engine)

12. **Network:**
    - network-manager-applet (NM system tray)

13. **Python:**
    - python-pyquery (Python library)

14. **Misc:**
    - yad (dialog tool)

### Medium Priority:
- nwg-displays (display configuration)
- mousepad (text editor)
- mpv + mpv-mpris (media player)
- nvtop (GPU monitoring)
- loupe (image viewer)
- cava (audio visualizer)
- qalculate-gtk (calculator)
- yt-dlp (YouTube downloader)

### Low Priority (Optional):
- gnome-system-monitor (system monitor)

### Battery Monitoring:
- acpi

### GTK Theme Engine:
- gtk-engine-murrine

### Fonts:
- adobe-source-code-pro-fonts
- noto-fonts-emoji
- ttf-droid
- ttf-fantasque-nerd
- ttf-jetbrains-mono-nerd
- ttf-victor-mono
- noto-fonts

## 🚀 How I Installed Gentoo

### These Are the Steps I Used

#### 1. Install Core System Tools First
```bash
# Install eix for fast package searching
sudo emerge -v app-portage/eix
sudo eix-update
```

#### 2. Install Hyprland Core
```bash
# Main compositor and ecosystem
sudo emerge -v gui-wm/hyprland gui-apps/hypridle gui-apps/hyprlock
```

#### 3. Install Core Wayland Tools
```bash

# Screenshots and wallpaper
sudo emerge -v gui-apps/grim gui-apps/slurp gui-apps/swappy gui-apps/awww gui-apps/hyprshot

#### 4. Install Clipboard Management
```bash
# Note: cliphist not available, use clipman instead
sudo emerge -v gui-apps/clipman gui-apps/wl-clipboard
```

#### 5. Install Notifications
```bash
sudo emerge -v gui-apps/swaync
# libnotify will be pulled in as dependency
```

#### 6. Install Audio Controls
```bash
sudo emerge -v media-sound/pamixer media-sound/pavucontrol media-sound/playerctl
```

#### 7. Install System Utilities
```bash
sudo emerge -v app-misc/brightnessctl media-gfx/imagemagick sys-apps/inxi gnome-base/gvfs app-editors/nano
```

#### 8. Install Qt Theming
```bash
# Note: qt6ct not available in Gentoo
sudo emerge -v x11-themes/kvantum x11-misc/qt5ct
```

**IMPORTANT - For QuickShell users:**
```bash
# Enable qml USE flag for Qt5Compat (required for GraphicalEffects)
echo 'dev-qt/qt5compat qml' | sudo tee -a /etc/portage/package.use/qt
sudo emerge -v dev-qt/qt5compat
```

#### 9. Install Network Manager Applet
```bash
sudo emerge -v gnome-extra/nm-applet
```

#### 10. Install Session Management
```bash
sudo emerge -v gui-apps/wlogout x11-misc/xdg-user-dirs
```

#### 11. Install Fonts
```bash
# Note: nerdfonts likely already installed
sudo emerge -v media-fonts/source-code-pro media-fonts/noto-emoji
```

#### 12. Install GTK Theme Engine
```bash
sudo emerge -v x11-themes/gtk-engines-murrine
```

#### 13. Install Battery Monitoring
```bash
sudo emerge -v sys-power/acpi
```

#### 14. Install Critical Tools for JaKooLit's Config
```bash
# YAD - REQUIRED for help dialogs and SDDM background prompts
# WALLUST - REQUIRED for wallpaper-based theming
# POLKIT-GNOME - REQUIRED for authentication dialogs
sudo emerge -v gnome-extra/yad x11-misc/wallust gnome-extra/polkit-gnome
```

#### 15. Install Python Libraries
```bash
sudo emerge -v dev-python/pyquery
```

#### 16. Install Optional Tools
```bash
sudo emerge -v app-editors/mousepad media-video/mpv sys-process/nvtop \
                media-gfx/loupe media-sound/cava gui-apps/nwg-displays \
                sci-calculators/qalculate-gtk net-misc/yt-dlp
```


## 💡 Important Tips for Gentoo Users

### Package Installation Tips:

1. **USE Flag Conflicts**: When emerge reports USE flag conflicts, use:
   ```bash
   sudo emerge -v --autounmask-write <package>
   sudo etc-update --automode -5
   sudo emerge -v <package>
   ```

2. **Check Package Availability**:
   ```bash
   eix <package-name>  # Fast search
   emerge -s <package-name>  # Standard search
   ```

3. **Installation Progress**: Large packages (webkit-gtk, mpv) can take 30+ minutes to compile.

4. **Dependency Resolution**: Portage will automatically handle dependencies, but review the list before proceeding.

### Hyprland-Specific Configuration:

1. **Start Polkit Agent**: Add to `~/.config/hypr/hyprland.conf`:
   ```bash
   exec-once = /usr/libexec/polkit-gnome-authentication-agent-1
   ```

2. **Start Clipboard Manager**: Add to hyprland.conf:
   ```bash
   exec-once = wl-paste --type text --watch clipman store
   exec-once = wl-paste --type image --watch clipman store
   ```

3. **Graphics Drivers**: Ensure proper driver installation:
   - **AMD**: `media-libs/mesa` with `VIDEO_CARDS="amdgpu radeonsi"`
   - **Intel**: `media-libs/mesa` with `VIDEO_CARDS="intel iris"`
   - **NVIDIA**: Follow Gentoo's NVIDIA guide (more complex for Wayland)

### Package Equivalents and Alternatives:

| Arch Package | Gentoo Equivalent | Notes |
|-------------|------------------|-------|
| `cliphist` | `gui-apps/clipman` | Functionally equivalent |
| `hyprpolkitagent` | `gnome-extra/polkit-gnome` | Compatible alternative |
| `qt6ct` | Not available | Use Qt6 native theming |
| `yad` | `gnome-extra/yad` | In guru overlay |
| `wallust` | `x11-misc/wallust` | In guru overlay |

### Troubleshooting:

1. **Package Not Found**: Check if guru overlay is enabled:
   ```bash
   eselect repository list
   ```

2. **Compilation Errors**: Check for missing dependencies or USE flags:
   ```bash
   emerge --info <package>
   ```

3. **Performance**: Consider using:
   ```bash
   # In /etc/portage/make.conf
   MAKEOPTS="-j$(nproc)"
   EMERGE_DEFAULT_OPTS="--jobs 4 --load-average $(nproc)"
   ```

### Post-Installation Configuration:

1. **Create Hyprland Desktop Entry** (for display managers):
   ```bash
   sudo mkdir -p /usr/local/share/wayland-sessions
   sudo tee /usr/local/share/wayland-sessions/hyprland.desktop << 'EOF'
   [Desktop Entry]
   Name=Hyprland
   Comment=An intelligent dynamic tiling Wayland compositor
   Exec=Hyprland
   Type=Application
   EOF
   ```

2. **Enable Services** (if using systemd):
   ```bash
   systemctl --user enable pipewire pipewire-pulse wireplumber
   ```

3. **Deploy JaKooLit Dotfiles**:
   ```bash
   git clone https://github.com/JaKooLit/Hyprland-Dots.git
   cd Hyprland-Dots
   # Follow JaKooLit's installation instructions
   ```

4. **Test Critical Components**:
   ```bash
   # Screenshot
   grim ~/test.png
   
   # Wallpaper theming
   wallust ~/Pictures/wallpaper.png
   
   # Dialog
   yad --info --text="Test dialog"
   ```

## 📖 Additional Resources

- **Gentoo Wiki - Wayland**: https://wiki.gentoo.org/wiki/Wayland
- **Gentoo Forums**: https://forums.gentoo.org/
- **Hyprland Discord**: https://discord.gg/hyprland
- **JaKooLit's Documentation**: https://github.com/JaKooLit/Hyprland-Dots/wiki

## ⚠️ Known Issues

1. **NVIDIA Users**: Wayland support on NVIDIA requires:
   - Driver version 495+
   - `nvidia-drm.modeset=1` kernel parameter
   - Environment variables in hyprland.conf

2. **VM Users**: Disable Bluetooth packages:
   ```bash
   # Skip bluez, bluez-utils, blueman installations
   ```

3. **Qt6 Applications**: Without qt6ct, theme using environment variables:
   ```bash
   export QT_QPA_PLATFORMTHEME=qt5ct  # Falls back to Qt5 theming
   ```

## 🎯 Quick Installation Script

For experienced users, here's a one-liner approach (review before running):

```bash
# Install all essential packages
sudo emerge -v \
  app-portage/eix \
  gui-wm/hyprland gui-apps/hypridle gui-apps/hyprlock \
  gui-apps/grim gui-apps/slurp gui-apps/swappy gui-apps/awww gui-apps/hyprshot \
  gui-apps/clipman gui-apps/swaync \
  media-sound/pamixer media-sound/pavucontrol media-sound/playerctl \
  app-misc/brightnessctl media-gfx/imagemagick sys-apps/inxi \
  gnome-base/gvfs x11-themes/kvantum x11-misc/qt5ct \
  gnome-extra/nm-applet gui-apps/wlogout x11-misc/xdg-user-dirs \
  media-fonts/source-code-pro media-fonts/noto-emoji \
  x11-themes/gtk-engines-murrine sys-power/acpi \
  gnome-extra/yad x11-misc/wallust gnome-extra/polkit-gnome \
  dev-python/pyquery
```

**Note**: USE flag conflicts will require --autounmask-write as shown above.

## 🎉 Verification

After installation, verify critical components:

```bash
# Check all binaries are available
which hyprland grim slurp swappy hyprshot clipman swaync \
      pamixer playerctl brightnessctl wallust yad

# Check polkit agent
ls /usr/libexec/polkit-gnome-authentication-agent-1

# Test eix
eix hyprland
```

If all commands succeed, you're ready to install JaKooLit's dotfiles!

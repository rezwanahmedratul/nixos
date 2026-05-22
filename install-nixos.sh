#!/usr/bin/env bash

######################################
# Install script for nixos
# Author:  Don Williams
# Date: June 27, 2005
#######################################

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Define log file
LOG_DIR="$(dirname "$0")"
LOG_FILE="${LOG_DIR}/install_$(date +"%Y-%m-%d_%H-%M-%S").log"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

# Function to print a section header
print_header() {
  echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║ ${1} ${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

# Function to print a configuration summary
print_summary() {
  echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║                 📋 Installation Configuration Summary                 ║${NC}"
  echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════════════╣${NC}"
  echo -e "${CYAN}║  🖥️  Hostname:        ${BLUE}${1}${NC}"
  echo -e "${CYAN}║  🎮 GPU Profile:      ${BLUE}${2}${NC}"
  echo -e "${CYAN}║  👤 System Username:  ${BLUE}${3}${NC}"
  echo -e "${CYAN}║  🌐 Timezone:         ${BLUE}${4}${NC}"
  echo -e "${CYAN}║  ⌨️  Keyboard Layout:  ${BLUE}${5}${NC}"
  echo -e "${CYAN}║  ⌨️  Keyboard Variant: ${BLUE}${6:-none}${NC}"
  echo -e "${CYAN}║  🖥️  Console Keymap:   ${BLUE}${7:-$5}${NC}"
  echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

# Function to print an error message
print_error() {
  echo -e "${RED}Error: ${1}${NC}"
}

# Function to print a success banner
print_success_banner() {
  echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║                 NixOS Installation Successful!                      ║${NC}"
  echo -e "${GREEN}║                                                                       ║${NC}"
  echo -e "${GREEN}║   Please reboot your system for changes to take full effect.          ║${NC}"
  echo -e "${GREEN}║                                                                       ║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

# Function to print a failure banner
print_failure_banner() {
  echo -e "${RED}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║                 NixOS Installation Failed!                          ║${NC}"
  echo -e "${RED}║                                                                       ║${NC}"
  echo -e "${RED}║   Please review the log file for details:                             ║${NC}"
  echo -e "${RED}║   ${LOG_FILE}                                                        ║${NC}"
  echo -e "${RED}║                                                                       ║${NC}"
  echo -e "${RED}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
}

print_header "Verifying System Requirements"

# Check for git
if ! command -v git &>/dev/null; then
  print_error "Git is not installed."
  echo -e "Please install git and pciutils are installed, then re-run the install script."
  echo -e "Example: nix-shell -p git pciutils"
  exit 1
fi

# Check for lspci (pciutils)
if ! command -v lspci &>/dev/null; then
  print_error "pciutils is not installed."
  echo -e "Please install git and pciutils,  then re-run the install script."
  echo -e "Example: nix-shell -p git pciutils"
  exit 1
fi

if [ -n "$(grep -i nixos </etc/os-release)" ]; then
  echo -e "${GREEN}Verified this is NixOS.${NC}"
else
  print_error "This is not NixOS or the distribution information is not available."
  exit 1
fi

print_header "Initial Setup"

echo -e "Default options are in brackets []"
echo -e "Just press enter to select the default"
sleep 2

print_header "Ensure In Home Directory"
cd "$HOME" || exit 1
echo -e "${GREEN}Current directory: $(pwd)${NC}"

print_header "Hostname Configuration"

# Critical warning about using "default" as hostname
echo -e "${RED}⚠️  IMPORTANT WARNING: Do NOT use 'default' as your hostname!${NC}"
echo -e "${RED}   The 'default' hostname is a template and will be overwritten during updates.${NC}"
echo -e "${RED}   This will cause you to lose your configuration!${NC}"
echo ""
echo -e "💡 Suggested hostnames: my-desktop, gaming-rig, workstation, nixos-laptop"
read -rp "Enter Your New Hostname: [ my-desktop ] " hostName
if [ -z "$hostName" ]; then
  hostName="my-desktop"
fi

# Double-check if user accidentally entered "default"
if [ "$hostName" = "default" ]; then
  echo -e "${RED}❌ Error: You cannot use 'default' as hostname. Please choose a different name.${NC}"
  read -rp "Enter a different hostname: " hostName
  if [ -z "$hostName" ] || [ "$hostName" = "default" ]; then
    echo -e "${RED}Setting hostname to 'my-desktop' to prevent configuration loss.${NC}"
    hostName="my-desktop"
  fi
fi

echo -e "${GREEN}✓ Hostname set to: $hostName${NC}"

print_header "GPU Profile Detection"

# Attempt automatic detection
DETECTED_PROFILE=""

has_nvidia=false
has_intel=false
has_amd=false
has_vm=false
detect_vm() {
  if command -v systemd-detect-virt &>/dev/null; then
    if systemd-detect-virt --quiet; then
      return 0
    fi
  fi
  for f in /sys/class/dmi/id/product_name /sys/class/dmi/id/sys_vendor; do
    if [ -r "$f" ] && grep -Eqi 'qemu|kvm|vmware|virtualbox|hyper-v|microsoft corporation|xen|parallels' "$f"; then
      return 0
    fi
  done
  return 1
}

if detect_vm; then
  has_vm=true
fi

if lspci | grep -qi 'vga\|3d\|display'; then
  while read -r line; do
    if echo "$line" | grep -Eq '\[10de:'; then
      has_nvidia=true
    elif echo "$line" | grep -Eq '\[1002:'; then
      has_amd=true
    elif echo "$line" | grep -Eq '\[8086:'; then
      has_intel=true
    elif echo "$line" | grep -Eq '\[(1af4|15ad|80ee|1b36|1414|1234|1013):'; then
      has_vm=true
    elif echo "$line" | grep -qi 'nvidia'; then
      has_nvidia=true
    elif echo "$line" | grep -qi 'amd\|ati\|advanced micro devices'; then
      has_amd=true
    elif echo "$line" | grep -qi 'intel'; then
      has_intel=true
    elif echo "$line" | grep -Eqi 'virtio|vmware|virtualbox|qxl|hyper-v|microsoft corporation|parallels|qemu|bochs|cirrus|svga|virtual'; then
      has_vm=true
    fi
  done < <(lspci -nn | grep -i 'vga\|3d\|display')

  if $has_vm; then
    DETECTED_PROFILE="vm"
  elif $has_nvidia && $has_amd; then
    DETECTED_PROFILE="amd-nvidia-hybrid"
  elif $has_nvidia && $has_intel; then
    DETECTED_PROFILE="nvidia-laptop"
  elif $has_nvidia; then
    DETECTED_PROFILE="nvidia"
  elif $has_amd; then
    DETECTED_PROFILE="amd"
  elif $has_intel; then
    DETECTED_PROFILE="intel"
  fi
fi

# Handle detected profile or fall back to manual input
if [ -n "$DETECTED_PROFILE" ]; then
  profile="$DETECTED_PROFILE"
  echo -e "${GREEN}Detected GPU profile: $profile${NC}"
  read -p "Correct? (Y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}GPU profile not confirmed. Falling back to manual selection.${NC}"
    profile="" # Clear profile to force manual input
  fi
fi

# If profile is still empty (either not detected or not confirmed), prompt manually
if [ -z "$profile" ]; then
  echo -e "${RED}Automatic GPU detection failed or no specific profile found.${NC}"
  read -rp "Enter Your Hardware Profile (GPU)
Options:
[ amd ]
amd-nvidia-hybrid
intel
nvidia
nvidia-laptop
vm
Please type out your choice: " profile
  if [ -z "$profile" ]; then
    profile="amd"
  fi
  echo -e "${GREEN}Selected GPU profile: $profile${NC}"
fi

print_header "⚠️  CRITICAL WARNING - Existing NixOS Detected"

backupname=$(date +"%Y-%m-%d-%H-%M-%S")
if [ -d "nixos" ]; then
  echo -e "${RED}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║                    ⚠️  IMPORTANT WARNING ⚠️                           ║${NC}"
  echo -e "${RED}║                                                                       ║${NC}"
  echo -e "${RED}║  An existing NixOS installation was detected at ~/nixos           ║${NC}"
  echo -e "${RED}║                                                                       ║${NC}"
  echo -e "${RED}║  This installer will COMPLETELY REPLACE your existing configuration!  ║${NC}"
  echo -e "${RED}║  All customizations, packages, and settings will be LOST!             ║${NC}"
  echo -e "${RED}║                                                                       ║${NC}"
  echo -e "${RED}║     ** A backup copy of your config will be created **                ║${NC}"
  echo -e "${RED}║      * You will have to merge your changes back **                    ║${NC}"
  echo -e "${RED}║                                                                       ║${NC}"
  echo -e "${RED}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${YELLOW}If you REALLY want to do a fresh installation (losing all customizations):${NC}"
  read -p "Type 'REPLACE' to continue with fresh install or Ctrl+C to cancel: " confirmation
  if [ "$confirmation" != "REPLACE" ]; then
    echo -e "${GREEN}Installation cancelled. ${NC}"
    exit 0
  fi
  echo -e "${GREEN}nixos exists, backing up to .config/nixos-backups folder.${NC}"
  if [ -d ".config/nixos-backups" ]; then
    echo -e "${GREEN}Moving current version of NixOS to backups folder.${NC}"
    mv "$HOME"/nixos .config/nixos-backups/"$backupname"
    sleep 1
  else
    echo -e "${GREEN}Creating the backups folder & moving NixOS to it.${NC}"
    mkdir -p .config/nixos-backups
    mv "$HOME"/nixos .config/nixos-backups/"$backupname"
    sleep 1
  fi
else
  echo -e "${GREEN}Thank you for choosing NixOS.${NC}"
  echo -e "${GREEN}I hope you find your time here enjoyable!${NC}"
fi

# Robust clone: retry a few times, prefer HTTP/1.1 to avoid HTTP/2 curl reset issues,
# increase postBuffer for large transfers, and use an explicit $HOME path.
REPO_URL="https://github.com/rezwanahmedratul/nixos.git"
TARGET_DIR="$HOME/nixos"
CLONE_ATTEMPTS=2
CLONE_SUCCESS=false

for attempt in $(seq 1 "$CLONE_ATTEMPTS"); do
  echo "Cloning repository (attempt $attempt/$CLONE_ATTEMPTS)..."
  # Force HTTP/1.1 and raise postBuffer for robustness; use shallow clone first.
  git -c http.version=HTTP/1.1 -c http.postBuffer=524288000 clone "$REPO_URL" -b main --depth=1 "$TARGET_DIR" && { CLONE_SUCCESS=true; break; }
  echo "Clone attempt $attempt failed; retrying in 2s..."
  sleep 2
done

if [ "$CLONE_SUCCESS" != true ]; then
  echo "Shallow clones failed; attempting a final full clone with HTTP/1.1..."
  git -c http.version=HTTP/1.1 -c http.postBuffer=524288000 clone "$REPO_URL" -b main "$TARGET_DIR" || {
    print_error "Failed to clone repository after $CLONE_ATTEMPTS attempts."
    print_failure_banner
    exit 1
  }
fi

cd "$TARGET_DIR" || { print_error "Could not change directory to $TARGET_DIR"; exit 1; }


print_header "Git Configuration"
echo "👤 Setting up git configuration for version control:"
echo "  This is needed for system updates and configuration management."
echo ""
installusername=$(echo $USER)
echo -e "Current username: ${GREEN}$installusername${NC}"
read -rp "Enter your full name for git commits [ $installusername ]: " gitUsername
if [ -z "$gitUsername" ]; then
  gitUsername="$installusername"
fi

echo "📧 Examples: john@example.com, jane.doe@company.org"
read -rp "Enter your email address for git commits [ $installusername@example.com ]: " gitEmail
if [ -z "$gitEmail" ]; then
  gitEmail="$installusername@example.com"
fi

echo -e "${GREEN}✓ Git name: $gitUsername${NC}"
echo -e "${GREEN}✓ Git email: $gitEmail${NC}"

print_header "Timezone Configuration"
echo "🌎 Common timezones:"
echo "  • US: America/New_York, America/Chicago, America/Denver, America/Los_Angeles"
echo "  • Europe: Europe/London, Europe/Berlin, Europe/Paris, Europe/Rome"
echo "  • Asia: Asia/Tokyo, Asia/Shanghai, Asia/Seoul, Asia/Kolkata"
echo "  • Australia: Australia/Sydney, Australia/Melbourne"
echo "  • UTC (Universal): UTC"
read -rp "Enter your timezone [ Asia/Dhaka ]: " timezone
if [ -z "$timezone" ]; then
  timezone="Asia/Dhaka"
fi
echo -e "${GREEN}✓ Timezone set to: $timezone${NC}"

print_header "Keyboard Layout Configuration"
echo "🌍 Common keyboard layouts:"
echo "  • us (US English) - default"
echo "  • us-intl (US International)"
echo "  • uk (UK English)"
echo "  • de (German)"
echo "  • fr (French)"
echo "  • es (Spanish)"
echo "  • it (Italian)"
echo "  • ru (Russian)"
echo "  • dvorak (Dvorak)"
read -rp "Enter your keyboard layout: [ us ] " keyboardLayout
if [ -z "$keyboardLayout" ]; then
  keyboardLayout="us"
fi
echo -e "${GREEN}✓ Keyboard layout set to: $keyboardLayout${NC}"

print_header "Keyboard Variant Configuration"
# Suggest a variant when user typed a variant-like layout
variant_suggestion=""
case "$keyboardLayout" in
dvorak | colemak | workman | intl | us-intl)
  variant_suggestion="$keyboardLayout"
  ;;
*) ;;
esac
read -rp "Enter your keyboard variant (e.g., dvorak) [ $variant_suggestion ]: " keyboardVariant
keyboardVariant="${keyboardVariant:-$variant_suggestion}"

# Normalize layout/variant to avoid accidentally forcing US for non-US layouts
# - Accept uppercase inputs; treat BR/DE/FR/ES/IT/RU/UK in variant field as layout
# - Map us-intl/intl and dvorak/colemak/workman to layout=us + appropriate variant
keyboardLayout=$(echo "$keyboardLayout" | tr '[:upper:]' '[:lower:]')
keyboardVariant=$(echo "$keyboardVariant" | tr '[:upper:]' '[:lower:]')

case "$keyboardLayout" in
us-intl | intl)
  keyboardLayout="us"
  if [ -z "$keyboardVariant" ]; then keyboardVariant="intl"; fi
  ;;
dvorak | colemak | workman)
  if [ -z "$keyboardVariant" ]; then keyboardVariant="$keyboardLayout"; fi
  keyboardLayout="us"
  ;;
*) ;;
esac

# If a layout accidentally ended up in the variant field, fix it
if [[ "$keyboardVariant" =~ ^(us|br|de|fr|es|it|ru|uk)$ ]]; then
  keyboardLayout="$keyboardVariant"
  keyboardVariant=""
fi

if [ -z "$keyboardVariant" ]; then
  echo -e "${GREEN}✓ Keyboard variant set to: none${NC}"
else
  echo -e "${GREEN}✓ Keyboard variant set to: $keyboardVariant${NC}"
fi

print_header "Console Keymap Configuration"
echo "⌨️  Console keymap (usually matches your keyboard layout):"
echo "  Most common: us, uk, de, fr, es, it, ru"
# Smart default: use keyboard layout as console keymap default if it's a common one
defaultConsoleKeyMap="$keyboardLayout"
if [[ ! "$keyboardLayout" =~ ^(us|uk|de|fr|es|it|ru|us-intl|dvorak)$ ]]; then
  defaultConsoleKeyMap="us"
fi
read -rp "Enter your console keymap: [ $defaultConsoleKeyMap ] " consoleKeyMap
if [ -z "$consoleKeyMap" ]; then
  consoleKeyMap="$defaultConsoleKeyMap"
fi
echo -e "${GREEN}✓ Console keymap set to: $consoleKeyMap${NC}"

print_header "Configuring Host and Profile"
mkdir -p hosts/"$hostName"
cp hosts/default/*.nix hosts/"$hostName"

# Show a nice summary and ask for confirmation before making changes
echo ""
print_summary "$hostName" "$profile" "$installusername" "$timezone" "$keyboardLayout" "$keyboardVariant" "$consoleKeyMap"
echo ""
echo -e "${YELLOW}Please review the configuration above.${NC}"
read -p "$(echo -e "${YELLOW}Continue with installation? (Y/N): ${NC}")" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${RED}Installation cancelled.${NC}"
  exit 1
fi

echo ""
echo -e "${GREEN}✓ Configuration accepted. Starting installation...${NC}"
echo ""
echo -e "${BLUE}Updating configuration files...${NC}"
echo -e "  ${CYAN}installusername:${NC} $installusername"
echo -e "  ${CYAN}hostName:${NC} $hostName"
echo -e "  ${CYAN}profile:${NC} $profile"
echo -e "  ${CYAN}timezone:${NC} $timezone"
echo -e "  ${CYAN}keyboardLayout:${NC} $keyboardLayout"
echo "  installusername: $installusername"
echo "  hostName: $hostName"
echo "  profile: $profile"

# Update flake.nix (simple pattern replacements that work)
# Create backup first, before any changes
cp ./flake.nix ./flake.nix.bak
# Use sed for hostname (more reliable)
sed -i 's|^[[:space:]]*host[[:space:]]*=[[:space:]]*"[^"]*"|    host = "'$hostName'"|' ./flake.nix.bak
# Use sed for profile (handles variable indentation)
sed -i 's|^[[:space:]]*profile[[:space:]]*=[[:space:]]*"[^"]*";|    profile = "'$profile'";|' ./flake.nix.bak
# Use sed for username (handles variable indentation)
sed -i 's|^[[:space:]]*username[[:space:]]*=[[:space:]]*"[^"]*";|    username = "'$installusername'";|' ./flake.nix.bak
echo -e "${GREEN}After sed replacements:${NC}"
grep -E "(host|profile|username) =" ./flake.nix.bak
cp ./flake.nix.bak ./flake.nix
rm ./flake.nix.bak

# Update timezone in system.nix
cp ./modules/core/system.nix ./modules/core/system.nix.bak
awk -v newtz="$timezone" '/^  time\.timeZone = / { sub(/"[^"]*"/, "\"" newtz "\""); } { print }' ./modules/core/system.nix.bak >./modules/core/system.nix
rm ./modules/core/system.nix.bak

# Update variables in host file (do all keys in one pass to avoid quoting issues)
cp ./hosts/$hostName/variables.nix ./hosts/$hostName/variables.nix.bak
awk -v v_user="$gitUsername" \
  -v v_email="$gitEmail" \
  -v v_kb="$keyboardLayout" \
  -v v_kv="$keyboardVariant" \
  -v v_ckm="$consoleKeyMap" '
  /^  gitUsername = /     { sub(/"[^"]*"/, "\"" v_user "\"") }
  /^  gitEmail = /        { sub(/"[^"]*"/, "\"" v_email "\"") }
  /^  keyboardLayout = /  { sub(/"[^"]*"/, "\"" v_kb "\"") }
  /^  keyboardVariant = / { sub(/"[^"]*"/, "\"" v_kv "\"") }
  /^  consoleKeyMap = /   { sub(/"[^"]*"/, "\"" v_ckm "\"") }
  { print }
' ./hosts/$hostName/variables.nix.bak >./hosts/$hostName/variables.nix
rm ./hosts/$hostName/variables.nix.bak

echo "Configuration files updated successfully!"

print_header "Git Configuration"
git config --global user.name "$gitUsername"
git config --global user.email "$gitEmail"
git add .
git config --global --unset-all user.name
git config --global --unset-all user.email

print_header "Generating Hardware Configuration -- Ignore ERROR: cannot access /bin"
sudo nixos-generate-config --show-hardware-config >./hosts/$hostName/hardware.nix

print_header "Setting Nix Configuration"
NIX_CONFIG="experimental-features = nix-command flakes"

print_header "Initiating NixOS Build"
read -p "Ready to run initial build? (Y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${RED}Build cancelled.${NC}"
  exit 1
fi

sudo nixos-rebuild boot --flake ~/nixos/#${profile}

# Check the exit status of the last command (nixos-rebuild)
if [ $? -eq 0 ]; then
  print_success_banner
else
  print_failure_banner
fi

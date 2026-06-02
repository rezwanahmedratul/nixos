#!/usr/bin/env bash
set -euo pipefail

# Use a dedicated narrow dark theme for the power menu
config="$HOME/.config/rofi/power-menu.rasi"

actions=$(echo -e "  Lock\n  Shutdown\n  Reboot\n  Suspend\n  Hibernate\n󰞘  Logout")

# Display logout menu
selected_option=$(echo -e "$actions" | rofi -dmenu -i -p "Power Menu" -config "${config}") || exit 0
selected_option=$(printf "%s" "$selected_option" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')

run_power_action() {
  local action="$1"
  systemctl "$action" || loginctl "$action"
}

# Perform actions based on the selected option
case "$selected_option" in
*Lock)
  loginctl lock-session
  ;;
*Shutdown)
  run_power_action poweroff
  ;;
*Reboot)
  run_power_action reboot
  ;;
*Suspend)
  run_power_action suspend
  ;;
*Hibernate)
  run_power_action hibernate
  ;;
*Logout)
  loginctl kill-session "$XDG_SESSION_ID"
  ;;
esac

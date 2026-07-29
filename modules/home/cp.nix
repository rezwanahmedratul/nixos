{ pkgs, ... }:

let
cp-session = pkgs.writeShellScriptBin "cp-session" ''
#!${pkgs.bash}/bin/bash

WS=$(hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq '.id')

# --- FORCE NEW WINDOWS ---
zen-beta -p CP --new-window "https://codeforces.com/" &
sleep 1

code --new-window "$HOME/Github/CP" &
sleep 2

# --- GET WINDOWS ONLY FROM CURRENT WORKSPACE ---
ZEN_ADDR=$(hyprctl clients -j | ${pkgs.jq}/bin/jq -r --argjson ws "$WS" '
  .[] | select(.workspace.id == $ws and .class == "zen-beta") | .address
' | head -n 1)

CODE_ADDR=$(hyprctl clients -j | ${pkgs.jq}/bin/jq -r --argjson ws "$WS" '
  .[] | select(.workspace.id == $ws and (.class | test("code|Code|vscode"; "i"))) | .address
' | head -n 1)

# --- POSITION ONLY THESE WINDOWS ---
if [ -n "$ZEN_ADDR" ]; then
  hyprctl dispatch movewindowpixel exact 0 24,address:$ZEN_ADDR
  hyprctl dispatch resizewindowpixel exact 560 976,address:$ZEN_ADDR
fi

if [ -n "$CODE_ADDR" ]; then
  hyprctl dispatch movewindowpixel exact 564 24,address:$CODE_ADDR
  hyprctl dispatch resizewindowpixel exact 1036 976,address:$CODE_ADDR
fi

# optional focus (current workspace only)
if [ -n "$ZEN_ADDR" ]; then
  hyprctl dispatch focuswindow "address:$ZEN_ADDR"
fi
'';
in
{
home.packages = [ cp-session ];
}
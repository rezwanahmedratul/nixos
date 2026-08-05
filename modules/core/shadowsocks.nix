{ config, pkgs, lib, ... }:

let
  commonPort = 12348;
  commonMethod = "chacha20-ietf-poly1305";

  secretsFile =
    if builtins.pathExists ./shadowsocks-secrets.json then
      ./shadowsocks-secrets.json
    else if builtins.pathExists /etc/shadowsocks-secrets.json then
      /etc/shadowsocks-secrets.json
    else if builtins.pathExists /home/ratul/nixos/modules/core/shadowsocks-secrets.json then
      /home/ratul/nixos/modules/core/shadowsocks-secrets.json
    else
      null;

  secrets =
    if secretsFile != null then
      builtins.fromJSON (builtins.readFile secretsFile)
    else
      { };

  serverNames = builtins.attrNames (lib.filterAttrs (n: v: n != "password") secrets);

  mkSS = { name, localPort }: {
    description = "Shadowsocks Client (${name})";
    after = [ "network.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.writeShellScript "run-${name}" ''
        SECRET_FILE="/etc/shadowsocks-secrets.json"
        LOCAL_SECRET="/home/ratul/nixos/modules/core/shadowsocks-secrets.json"

        if [ -f "$SECRET_FILE" ]; then
          SEC_FILE="$SECRET_FILE"
        elif [ -f "$LOCAL_SECRET" ]; then
          SEC_FILE="$LOCAL_SECRET"
        else
          echo "Warning: Shadowsocks secret file not found at $SECRET_FILE or $LOCAL_SECRET. Skipping ${name}..." >&2
          exit 0
        fi

        SERVER=$(${pkgs.jq}/bin/jq -r '(.["${name}"] | if type == "object" then .server else . end) // empty' "$SEC_FILE" 2>/dev/null)
        PASSWORD=$(${pkgs.jq}/bin/jq -r '(.["${name}"] | if type == "object" then .password else null end) // .password // empty' "$SEC_FILE" 2>/dev/null)

        if [ -z "$SERVER" ] || [ "$SERVER" = "null" ]; then
          echo "Warning: Server IP for ${name} not found in secret file. Skipping ${name}..." >&2
          exit 0
        fi

        if [ -z "$PASSWORD" ] || [ "$PASSWORD" = "null" ]; then
          echo "Warning: Password for ${name} not found in secret file. Skipping ${name}..." >&2
          exit 0
        fi

        exec ${pkgs.shadowsocks-rust}/bin/sslocal \
          -b "127.0.0.1:${toString localPort}" \
          -s "$SERVER:${toString commonPort}" \
          -m "${commonMethod}" \
          -U \
          -k "$PASSWORD"
      ''}";
      Restart = "always";
      RestartSec = 5;
    };
  };
in
{
  # 🚀 Services
  systemd.services = lib.listToAttrs (
    lib.imap0 (idx: name: {
      inherit name;
      value = mkSS {
        inherit name;
        localPort = 1081 + idx;
      };
    }) serverNames
  );
}
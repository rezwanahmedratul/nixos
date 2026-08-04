{ config, pkgs, lib, ... }:

let
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
          echo "Error: Shadowsocks secret file not found at $SECRET_FILE or $LOCAL_SECRET" >&2
          exit 1
        fi

        SERVER=$(${pkgs.jq}/bin/jq -r '.["${name}"].server // .["${name}"] // empty' "$SEC_FILE")
        PASSWORD=$(${pkgs.jq}/bin/jq -r '.["${name}"].password // .password // empty' "$SEC_FILE")

        if [ -z "$SERVER" ] || [ "$SERVER" = "null" ]; then
          echo "Error: Server IP for ${name} not found in secret file." >&2
          exit 1
        fi

        if [ -z "$PASSWORD" ] || [ "$PASSWORD" = "null" ]; then
          echo "Error: Password not found in secret file." >&2
          exit 1
        fi

        exec ${pkgs.shadowsocks-rust}/bin/sslocal -c /etc/${name}.json -s "$SERVER" -k "$PASSWORD"
      ''}";
      Restart = "always";
      RestartSec = 5;
    };
  };
in
{
  # 🔧 Config files (JSON without hardcoded passwords or server IPs)
  environment.etc = {
    "shadowsocks-1.json".text = ''
    {
      "server_port": 12348,
      "local_address": "127.0.0.1",
      "local_port": 1081,
      "method": "chacha20-ietf-poly1305",
      "mode": "tcp_and_udp"
    }
    '';

    "shadowsocks-2.json".text = ''
    {
      "server_port": 12348,
      "local_address": "127.0.0.1",
      "local_port": 1082,
      "method": "chacha20-ietf-poly1305",
      "mode": "tcp_and_udp"
    }
    '';

    "shadowsocks-3.json".text = ''
    {
      "server_port": 12348,
      "local_address": "127.0.0.1",
      "local_port": 1083,
      "method": "chacha20-ietf-poly1305",
      "mode": "tcp_and_udp"
    }
    '';
  };

  # 🚀 Services
  systemd.services = {
    shadowsocks-1 = mkSS {
      name = "shadowsocks-1";
      localPort = 1081;
    };

    shadowsocks-2 = mkSS {
      name = "shadowsocks-2";
      localPort = 1082;
    };

    shadowsocks-3 = mkSS {
      name = "shadowsocks-3";
      localPort = 1083;
    };
  };
}
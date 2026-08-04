{ config, pkgs, lib, ... }:

let
  secretsFile = /. + "${toString ./.}/shadowsocks-secrets.nix";
  secrets = if builtins.pathExists secretsFile
    then import secretsFile
    else { password = "CHANGE_ME"; };

  mkSS = { name, server, localPort }: {
    description = "Shadowsocks Client (${name})";
    after = [ "network.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.shadowsocks-rust}/bin/sslocal -c /etc/${name}.json";
      Restart = "always";
      RestartSec = 5;
    };
  };
in
{
  # 🔧 Config files (your original JSONs)
  environment.etc = {
    "shadowsocks-1.json".text = ''
    {
      "server": "64.20.10.126",
      "server_port": 12348,
      "local_address": "127.0.0.1",
      "local_port": 1081,
      "password": "${secrets.password}",
      "method": "chacha20-ietf-poly1305",
      "mode": "tcp_and_udp"
    }
    '';

    "shadowsocks-2.json".text = ''
    {
      "server": "64.20.10.49",
      "server_port": 12348,
      "local_address": "127.0.0.1",
      "local_port": 1082,
      "password": "${secrets.password}",
      "method": "chacha20-ietf-poly1305",
      "mode": "tcp_and_udp"
    }
    '';

    "shadowsocks-3.json".text = ''
    {
      "server": "208.240.24.65",
      "server_port": 12348,
      "local_address": "127.0.0.1",
      "local_port": 1083,
      "password": "${secrets.password}",
      "method": "chacha20-ietf-poly1305",
      "mode": "tcp_and_udp"
    }
    '';
  };

  # 🚀 Services
  systemd.services = {
    shadowsocks-1 = mkSS {
      name = "shadowsocks-1";
      server = "64.20.10.126";
      localPort = 1081;
    };

    shadowsocks-2 = mkSS {
      name = "shadowsocks-2";
      server = "64.20.10.49";
      localPort = 1082;
    };

    shadowsocks-3 = mkSS {
      name = "shadowsocks-3";
      server = "208.240.24.65";
      localPort = 1083;
    };
  };
}
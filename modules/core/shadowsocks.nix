{ config, pkgs, lib, ... }:

let
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
      "server": "206.245.171.240",
      "server_port": 12348,
      "local_address": "127.0.0.1",
      "local_port": 1081,
      "password": "T8@qN5#vX3rB!1cE",
      "method": "chacha20-ietf-poly1305",
      "mode": "tcp_and_udp"
    }
    '';

    "shadowsocks-2.json".text = ''
    {
      "server": "64.190.17.2",
      "server_port": 12348,
      "local_address": "127.0.0.1",
      "local_port": 1082,
      "password": "T8@qN5#vX3rB!1cE",
      "method": "chacha20-ietf-poly1305",
      "mode": "tcp_and_udp"
    }
    '';

    "shadowsocks-3.json".text = ''
    {
      "server": "64.190.17.79",
      "server_port": 12348,
      "local_address": "127.0.0.1",
      "local_port": 1083,
      "password": "T8@qN5#vX3rB!1cE",
      "method": "chacha20-ietf-poly1305",
      "mode": "tcp_and_udp"
    }
    '';
  };

  # 🚀 Services
  systemd.services = {
    shadowsocks-1 = mkSS {
      name = "shadowsocks-1";
      server = "206.245.171.240"; # not used anymore, but kept for structure
      localPort = 1081;
    };

    shadowsocks-2 = mkSS {
      name = "shadowsocks-2";
      server = "64.190.17.2";
      localPort = 1082;
    };

    shadowsocks-3 = mkSS {
      name = "shadowsocks-3";
      server = "64.190.17.79";
      localPort = 1083;
    };
  };
}
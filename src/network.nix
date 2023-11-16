{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  networks = config.systemd.network.networks;
  isLocal = config.networking.domain == "local";
in {
  options = with lib; {
  };
  imports = lib.signal.fs.path.listFilePaths ./network;
  config = {
    networking.nftables = {
      enable = true;
    };
    networking.wireless.iwd = {
      enable = lib.mkDefault true;
      settings = {
        Network = {
          EnableIPv6 = true;
          NameResolvingService = "systemd";
        };
        Settings = {
          AutoConnect = true;
        };
      };
    };
    networking.useNetworkd = true;
    systemd.network = {
      enable = lib.mkDefault true;
      wait-online = {
        anyInterface = lib.mkDefault true;
      };
      networks."eth" = {
        enable = true;
        matchConfig = {
          Type = "ether";
          Name = "enp*";
        };
        linkConfig = {};
        networkConfig = {
          DHCP = lib.mkDefault "yes";
          MulticastDNS = lib.mkDefault (
            if isLocal
            then "yes"
            else "no"
          );
          LLMNR = lib.mkDefault "no";
        };
        routes = lib.mkDefault [
          {
            routeConfig = {
              Gateway = "_dhcp4";
            };
          }
          {
            routeConfig = {
              Gateway = "_ipv6ra";
            };
          }
        ];
      };
      networks."wlan" = {
        enable = true;
        matchConfig = {
          Type = "wlan";
        };
        linkConfig = {
          Unmanaged = lib.mkDefault (
            if config.networking.networkmanager.enable
            then "yes"
            else "no"
          );
        };
        networkConfig = {
          DHCP = lib.mkDefault "yes";
          MulticastDNS = lib.mkDefault (
            if isLocal
            then "yes"
            else "no"
          );
          LLMNR = lib.mkDefault "no";
          IgnoreCarrierLoss = "3s";
        };
        routes = lib.mkDefault [
          {
            routeConfig = {
              Gateway = "_dhcp4";
            };
          }
          {
            routeConfig = {
              Gateway = "_ipv6ra";
            };
          }
        ];
      };
    };
  };
}

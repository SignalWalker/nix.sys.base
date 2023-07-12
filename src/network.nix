{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
in {
  options = with lib; {
  };
  imports = lib.signal.fs.path.listFilePaths ./network;
  config = {
    systemd.network = {
      enable = lib.mkDefault true;
      networks."eth" = {
        enable = true;
        matchConfig = {
          Type = "ether";
          Name = "enp*";
        };
        networkConfig = {
          DHCP = lib.mkDefault "yes";
          MulticastDNS = lib.mkDefault (
            if config.networking.domain == "local"
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
    };
  };
}

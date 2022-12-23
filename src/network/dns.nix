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
    services.resolved = {
      multicastDns = mkEnableOption "MulticastDNS support";
    };
  };
  imports = [];
  config = {
    services.resolved = {
      enable = true;
      domains = config.networking.search ++ ["~."];
      multicastDns = lib.mkDefault (config.networking.domain == "local");
      llmnr = lib.mkDefault "false";
      fallbackDns = [
        "9.9.9.10"
        "2620:fe::10"
        "149.112.112.112"
        "2620:fe::fe"
      ];
      extraConfig = let
        mdns =
          if config.services.resolved.multicastDns
          then "yes"
          else "no";
      in ''
        DNS=9.9.9.9 2620:fe::9
        MulticastDNS=${mdns}
      '';
    };
  };
}

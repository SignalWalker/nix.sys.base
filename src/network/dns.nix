{
  config,
  lib,
  ...
}:
with builtins;
let
  resolved = config.services.resolved;
in
{
  options = with lib; {
    services.resolved = {
      dns = mkOption {
        type = types.listOf types.str;
        default = config.networking.nameservers ++ [
          "9.9.9.9"
          "2620:fe::9"
        ];
      };
      multicastDns = mkEnableOption "MulticastDNS support";
    };
  };
  imports = [ ];
  config = {
    networking.networkmanager = {
      dns = "systemd-resolved";
    };
    services.resolved = {
      enable = true;
      domains = config.networking.search ++ [ "~." ];
      multicastDns = lib.mkDefault (config.networking.domain == "local");
      llmnr = lib.mkDefault "false";
      fallbackDns = [
        "9.9.9.10"
        "2620:fe::10"
        "149.112.112.112"
        "2620:fe::fe"
      ];
      extraConfig =
        let
          mdns = if resolved.multicastDns then "yes" else "no";
        in
        ''
          DNS=${toString resolved.dns}
          MulticastDNS=${mdns}
        '';
    };
  };
}

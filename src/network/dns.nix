{
  config,
  lib,
  ...
}:
let
  resolved = config.services.resolved;
in
{
  options =
    let
      inherit (lib) mkOption types mkEnableOption;
    in
    {
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
      multicastDns = lib.mkDefault (config.networking.domain == "local");
      settings = {
        "Resolve" =
          let
            mdns = if resolved.multicastDns then "yes" else "no";
          in
          {
            "Domains" = config.networking.search ++ [ "~." ];
            "LLMNR" = lib.mkDefault "false";
            "DNS" = toString resolved.dns;
            "MulticastDNS" = mdns;
            "FallbackDNS" = [
              "9.9.9.10"
              "2620:fe::10"
              "149.112.112.112"
              "2620:fe::fe"
            ];
          };
      };
    };
  };
}

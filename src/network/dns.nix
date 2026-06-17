{
  config,
  lib,
  ...
}:
let
  resolved = config.services.resolved;
  avahi = config.services.avahi;
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
    services.avahi = {
      enable = true;
      openFirewall = false;
      nssmdns4 = true;
      nssmdns6 = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };
    services.resolved = {
      enable = true;
      multicastDns = true;
      settings = {
        "Resolve" =
          let
            mdns = if resolved.multicastDns then (if avahi.enable then "resolve" else "yes") else "no";
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

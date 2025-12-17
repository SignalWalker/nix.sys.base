{
  config,
  lib,
  ...
}:
let
  ts = config.services.tailscale;
in
{
  options =
    let
      inherit (lib) mkOption types;
    in
    {
      services.tailscale = {
        tailnet = {
          name = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
        };
      };
    };
  disabledModules = [ ];
  imports = [ ];
  config = lib.mkIf ts.enable (
    lib.mkMerge [
      {
        networking.firewall.checkReversePath = "loose";
        systemd.network = {
          wait-online.ignoredInterfaces = [ "tailscale0" ];
          networks."tailscale" = {
            matchConfig = {
              Name = "tailscale*";
            };
            linkConfig = {
              Unmanaged = true;
            };
          };
        };
      }
      (lib.mkIf (ts.tailnet.name != null) {
        networking.nameservers = [ "100.100.100.100" ];
        networking.search = [ ts.tailnet.name ];
      })
    ]
  );
  meta = { };
}

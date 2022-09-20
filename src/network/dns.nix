{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
in {
  options = with lib; {};
  imports = [];
  config = {
    services.resolved = {
      enable = true;
      domains = ["~."];
      extraConfig = ''
        DNS=9.9.9.9 2620:fe::9
      '';
      fallbackDns = [
        "149.112.112.112"
        "2620:fe::fe"
      ];
    };
  };
}

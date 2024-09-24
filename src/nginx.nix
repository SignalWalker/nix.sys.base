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
  disabledModules = [];
  imports = [];
  config = {
    services.nginx.virtualHostDefaults = {
      blockAgents = {
        enable = true;
        agents = lib.mkOptionDefault [
          "SemrushBot"
          "facebookexternalhit"
          "facebookcatalog"
          "meta-externalagent"
          "meta-externalfetcher"
          "DotBot"
        ];
      };
    };
  };
  meta = {};
}

{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  wg = config.signal.network.wireguard;
  wg-signal = wg.networks."wg-signal";
in {
  options = with lib; {};
  disabledModules = [];
  imports = [];
  config = {
    signal.network.wireguard.networks."wg-signal" = {
      enable = wg-signal ? privateKeyFile;
      port = 51860;
      peers = [
        {
          # terra
          publicKey = "kFTqdNZD4LieJ+05tsELgTmAmFukny/6fzCHjixbEGc=";
          allowedIps = ["172.24.86.1/32" "fd24:fad3:8246::1/128"];
          endpoint = "home.ashwalker.net";
        }
        {
          # artemis
          publicKey = "RbU3KFqzrogX2zkscu7pu1t1QcyJz4Vr3lesveicI3Y=";
          allowedIps = ["172.24.86.2/32" "fd24:fad3:8249::2/128"];
        }
      ];
    };
    networking.extraHosts = ''
      172.24.86.1 terra.ashwalker.net
      fd24:fad3:8246::1 terra.ashwalker.net
      172.24.86.2 artemis.ashwalker.net
      fd24:fad3:8246::2 artemis.ashwalker.net
    '';
  };
  meta = {};
}

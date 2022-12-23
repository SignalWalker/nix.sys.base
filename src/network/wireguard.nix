{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  wg = config.signal.network.wireguard;
in {
  options = with lib; {
    signal.network.wireguard = {
      privateKeyFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Runtime path of a file from which to read the wireguard private key.";
      };
      port = mkOption {
        type = types.port;
        default = 51860;
      };
      peers = mkOption {
        type = types.listOf (types.submoduleWith {
          modules = [
            ({
              config,
              lib,
              ...
            }: {
              options = with lib; {
                wireguardPeerConfig = mkOption {
                  type = let
                    cfg = config;
                  in
                    types.submoduleWith {
                      modules = [
                        ({
                          config,
                          lib,
                          ...
                        }: {
                          freeformType = lib.types.anything;
                          options = with lib; {
                          };
                        })
                      ];
                    };
                  default = {};
                };
              };
            })
          ];
        });
        default = [];
      };
    };
  };
  imports = [];
  config = lib.mkIf (wg.privateKeyFile != null) {
    systemd.network.netdevs."wg-signal" = {
      enable = true;
      netdevConfig = {
        Name = "wg-signal";
        Kind = "wireguard";
        Description = "SignalNet";
      };
      wireguardConfig = {
        PrivateKeyFile = wg.privateKeyFile;
        ListenPort = wg.port;
      };
      wireguardPeers = map (peer: {inherit (peer) wireguardPeerConfig;}) wg.peers;
    };
  };
}

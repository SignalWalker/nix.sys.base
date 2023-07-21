{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  wg = config.signal.network.wireguard;
  wgPeer = types.submoduleWith {
    modules = [
      ({
        config,
        lib,
        pkgs,
        ...
      }: {
        options = with lib; {
          publicKey = mkOption {
            type = types.str;
          };
          presharedKeyFile = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          allowedIps = mkOption {
            type = types.listOf types.str;
            default = [];
          };
          endpoint = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          persistentKeepAlive = mkOption {
            type = types.int.u16;
            default = 0;
          };
          routeTable = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          routeMetric = mkOption {
            type = types.nullOr types.int.u32;
            default = null;
          };
        };
        config = {};
      })
    ];
  };
in {
  options = with lib; {
    signal.network.wireguard = {
      networks = mkOption {
        type = types.attrsOf (types.submoduleWith {
          modules = [
            ({
              config,
              lib,
              pkgs,
              name,
              ...
            }: {
              options = with lib; {
                enable = mkEnableOption "wireguard network :: ${name}";
                privateKeyFile = mkOption {
                  type = types.str;
                  description = "runtime path of private key file";
                };
                port = mkOption {
                  type = types.either types.port (types.enum ["auto"]);
                  example = 51860;
                  default = "auto";
                };
                firewallMark = mkOption {
                  type = types.nullOr types.int.u32;
                  default = null;
                };
                routeTable = mkOption {
                  type = types.str;
                  default = "0";
                };
                routeMetric = mkOption {
                  type = types.nullOr types.int.u32;
                  default = null;
                };
                peers = mkOption {
                  type = types.listOf wgPeer;
                  default = [];
                };
              };
              config = {};
            })
          ];
        });
      };
    };
  };
  imports = [];
  config = lib.mkMerge ([
    ]
    ++ (map (netname: let
      network = wg.networks.${netname};
    in {
      systemd.network.netdevs.${netname} = {
        enable = network.enable;
        wireguardConfig = lib.mkMerge [
          {
            ListenPort = network.port;
            PrivateKeyFile = network.privateKeyFile;
            RouteTable = network.routeTable;
          }
          (lib.mkIf (network.firewallMark != null) {
            FirewallMark = network.firewallMark;
          })
          (lib.mkIf (network.routeMetric != null) {
            RouteMetric = network.routeMetric;
          })
        ];
        wireguardPeers = map (peer:
          lib.mkMerge [
            {
              PublicKey = peer.publicKey;
              AllowedIPs = peer.allowedIps;
              PersistentKeepAlive = peer.persistentKeepAlive;
            }
            (lib.mkIf (peer.presharedKeyFile != null) {
              PresharedKeyFile = peer.presharedKeyFile;
            })
            (lib.mkIf (peer.endpoint != null) {
              Endpoint = peer.endpoint;
            })
            (lib.mkIf (peer.routeTable != null) {
              RouteTable = peer.routeTable;
            })
            (lib.mkIf (peer.routeMetric != null) {
              RouteMetric = peer.routeMetric;
            })
          ])
        network.peers;
      };
    }) (attrNames wg.networks)));
}

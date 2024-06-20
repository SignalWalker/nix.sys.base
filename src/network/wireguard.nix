{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  wg = config.signal.network.wireguard;
  wgPeer = lib.types.submoduleWith {
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
            type = types.int;
            default = 0;
          };
          routeTable = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          routeMetric = mkOption {
            type = types.nullOr types.int;
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
                  type = types.nullOr types.int;
                  default = null;
                };
                routeTable = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                };
                routeMetric = mkOption {
                  type = types.nullOr types.int;
                  default = null;
                };
                peers = mkOption {
                  type = types.listOf wgPeer;
                  default = [];
                };
                addresses = mkOption {
                  type = types.listOf types.str;
                  default = [];
                };
                addPrefixRoute = mkOption {
                  type = types.bool;
                  default = true;
                };
                dns = mkOption {
                  type = types.listOf types.str;
                  default = [];
                };
                domains = mkOption {
                  type = types.listOf types.str;
                  default = [];
                };
                extraNetdevConfig = mkOption {
                  type = types.attrsOf types.anything;
                  default = {};
                };
                extraNetworkConfig = mkOption {
                  type = types.attrsOf types.anything;
                  default = {};
                };
              };
              config = {};
            })
          ];
        });
        default = {};
      };
    };
  };
  imports = [];
  config = {
    environment.systemPackages = with pkgs; [wireguard-tools];
    systemd.network.netdevs =
      std.mapAttrs (netname: network: (lib.mkMerge [
        {
          enable = network.enable;
          netdevConfig = {
            Name = netname;
            Kind = "wireguard";
          };
          wireguardConfig = lib.mkMerge [
            {
              ListenPort = network.port;
              PrivateKeyFile = network.privateKeyFile;
            }
            (lib.mkIf (network.routeTable != null) {
              RouteTable = network.routeTable;
            })
            (lib.mkIf (network.firewallMark != null) {
              FirewallMark = network.firewallMark;
            })
            (lib.mkIf (network.routeMetric != null) {
              RouteMetric = network.routeMetric;
            })
          ];
          wireguardPeers =
            map (peer: lib.mkMerge [
                {
                  PublicKey = peer.publicKey;
                  AllowedIPs = peer.allowedIps;
                  PersistentKeepalive = peer.persistentKeepAlive;
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
        }
        network.extraNetdevConfig
      ]))
      wg.networks;

    systemd.network.networks =
      std.mapAttrs (netname: network: (lib.mkMerge [
        {
          enable = network.enable;
          matchConfig = {
            Name = netname;
            Type = "wireguard";
          };
          linkConfig = {
            RequiredForOnline = "no";
          };
          networkConfig = {
            # DHCP = false;
            # LLMNR = false;
          };
          dns = network.dns;
          addresses =
            map (addr: {
                Address = addr;
                AddPrefixRoute =
                  if network.addPrefixRoute
                  then "yes"
                  else "no";
                # Scope = "link";
            })
            network.addresses;
        }
        (lib.mkIf (network.domains != []) {
          domains = network.domains;
        })
        network.extraNetworkConfig
      ]))
      wg.networks;
  };
}

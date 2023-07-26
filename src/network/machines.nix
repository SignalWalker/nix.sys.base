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
  machines = config.signal.machines;
  local = machines.${config.networking.hostName} or {};
  addressType = lib.types.submoduleWith {
    modules = [
      ({
        config,
        lib,
        pkgs,
        ...
      }: {
        options = with lib; {
          address = mkOption {
            type = types.str;
          };
          mask = mkOption {
            type = types.int;
          };
          __toString = mkOption {
            type = types.anything;
            readOnly = true;
            default = self: "${self.address}/${toString self.mask}";
          };
        };
        config = {};
      })
    ];
  };
in {
  options = with lib; {
    signal.machines = mkOption {
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
              hostName = mkOption {
                type = types.str;
                default = name;
              };
              domain = mkOption {
                type = types.str;
                default = "local";
              };
              fqdn = mkOption {
                type = types.str;
                readOnly = true;
                default = "${config.hostName}.${config.domain}";
              };
              wireguard = {
                publicKey = mkOption {
                  type = types.str;
                };
                allowedIps = mkOption {
                  type = types.listOf (types.coercedTo types.str (addr: let
                      matches = match "([^/]+)/(.*)" addr;
                    in {
                      address = elemAt matches 0;
                      mask = toInt (elemAt matches 1);
                    })
                    addressType);
                  default = [];
                };
                addresses = mkOption {
                  type = types.listOf (types.coercedTo types.str (addr: let
                      matches = match "([^/]+)/(.*)" addr;
                    in {
                      address = elemAt matches 0;
                      mask = toInt (elemAt matches 1);
                    })
                    addressType);
                  default =
                    map ({
                      address,
                      mask,
                      ...
                    }: {
                      inherit address;
                      mask =
                        if mask == 32
                        then 24
                        else 48;
                    })
                    config.wireguard.allowedIps;
                };
                endpoint = mkOption {
                  type = types.nullOr types.str;
                  default =
                    if config.domain != "local"
                    then "${config.fqdn}:51860"
                    else null;
                };
              };
              nix = {
                build = {
                  enable = mkEnableOption "remote builds on this device";
                  user = mkOption {
                    type = types.str;
                    default = "nixremote";
                  };
                  group = mkOption {
                    type = types.str;
                    default = config.nix.build.user;
                  };
                  authorizedKeys = mkOption {
                    type = types.listOf types.str;
                    default = [];
                  };
                  fqdn = mkOption {
                    type = types.str;
                    default = config.fqdn;
                  };
                  systems = mkOption {
                    type = types.listOf types.str;
                  };
                  supportedFeatures = mkOption {
                    type = types.listOf types.str;
                    default = [];
                  };
                  maxJobs = mkOption {
                    type = types.int;
                    default = 1;
                  };
                  speedFactor = mkOption {
                    type = types.int;
                    default = 1;
                  };
                  sshKey = mkOption {
                    type = types.str;
                  };
                };
              };
            };
            config = {};
          })
        ];
      });
      default = {};
    };
  };
  disabledModules = [];
  imports = [];
  config = lib.mkMerge [
    {
      signal.machines = {
        "terra" = {
          wireguard = {
            publicKey = "kFTqdNZD4LieJ+05tsELgTmAmFukny/6fzCHjixbEGc=";
            allowedIps = ["172.24.86.1/32" "fd24:fad3:8246::1/128"];
            endpoint = "home.ashwalker.net:51860";
          };
          nix = {
            build = {
              enable = true;
              authorizedKeys = config.users.users.ash.openssh.authorizedKeys.keys;
              fqdn = "terra.tail3d611.ts.net";
              systems = ["x86_64-linux"];
              supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "uid-range" "kvm" "ca-derivations"];
              maxJobs = 8;
              speedFactor = 1;
            };
          };
        };
        "artemis" = {
          wireguard = {
            publicKey = "RbU3KFqzrogX2zkscu7pu1t1QcyJz4Vr3lesveicI3Y=";
            allowedIps = ["172.24.86.2/32" "fd24:fad3:8249::2/128"];
          };
        };
      };
      signal.network.wireguard.networks."wg-signal" = {
        enable = wg-signal ? privateKeyFile;
        port = 51860;
        addresses = map (addr: toString addr) (local.wireguard.addresses or []);
        peers = foldl' (peers: name: let
          mcn = machines.${name};
        in
          if mcn.fqdn == config.networking.fqdn
          then peers
          else
            (peers
              ++ [
                {
                  inherit (mcn.wireguard) publicKey endpoint;
                  allowedIps = map (addr: toString addr) mcn.wireguard.allowedIps;
                }
              ])) [] (attrNames machines);
      };
      networking = {
        extraHosts = ''
          172.24.86.1 terra.ashwalker.net
          fd24:fad3:8246::1 terra.ashwalker.net
          172.24.86.2 artemis.ashwalker.net
          fd24:fad3:8246::2 artemis.ashwalker.net
        '';
        firewall = {
          trustedInterfaces = ["wg-signal"];
          allowedUDPPorts = [51860];
        };
      };
      nix = {
        distributedBuilds = true;
        buildMachines = foldl' (peers: name: let
          mcn = machines.${name};
          build = mcn.nix.build;
        in
          if (mcn.fqdn == config.networking.fqdn || !build.enable)
          then peers
          else
            (peers
              ++ [
                {
                  hostName = build.fqdn;
                  protocol = "ssh-ng";
                  sshUser = build.user;
                  inherit (build) maxJobs supportedFeatures systems speedFactor sshKey;
                }
              ])) [] (attrNames machines);
      };
    }
    # if this is a build machine
    (lib.mkIf (local.nix.build.enable or false) (let
      build = local.nix.build;
    in {
      users.users.${build.user} = {
        description = "Nix remote builder";
        isSystemUser = true;
        createHome = true;
        home = "/var/lib/${build.user}";
        homeMode = "740";
        shell = pkgs.bash;
        openssh.authorizedKeys.keys = build.authorizedKeys;
        group = build.group;
      };
      users.groups.${build.group} = {};
      nix.settings.trusted-users = [build.user];
    }))
  ];
  meta = {};
}

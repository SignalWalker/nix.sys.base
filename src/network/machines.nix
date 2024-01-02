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
  local = machines.${config.signal.machine.signalName} or {};
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
          type = mkOption {
            type = types.enum ["v4" "v6"];
            readOnly = true;
            default =
              if std.hasInfix ":" config.address
              then "v6"
              else "v4";
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
  addressTypeCoerced = with lib;
    types.coercedTo types.str (addr: let
      matches = match "([^/]+)/(.*)" addr;
    in {
      address = elemAt matches 0;
      mask = toInt (elemAt matches 1);
    })
    addressType;
in {
  options = with lib; {
    signal.machine = {
      signalName = mkOption {
        type = types.nullOr types.str;
        default = config.networking.hostName;
      };
    };
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
                  type = types.listOf addressTypeCoerced;
                  default = [];
                };
                addresses = mkOption {
                  type = types.listOf addressTypeCoerced;
                  default =
                    map ({
                      address,
                      mask,
                      type,
                      ...
                    }: {
                      inherit address;
                      mask =
                        if type == "v4"
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
      signal.machines = let
        prefix = {
          v4 = "172.24.86";
          v6 = "fd24:fad3:8246";
        };
        genAddrs = index: [
          "${prefix.v4}.${toString index}/32"
          "${prefix.v6}::${toString index}/128"
        ];
        port = toString wg-signal.port;
      in {
        "terra" = {
          wireguard = {
            publicKey = "kFTqdNZD4LieJ+05tsELgTmAmFukny/6fzCHjixbEGc=";
            allowedIps = genAddrs 1;
            endpoint = "home.ashwalker.net:${port}";
          };
          nix = {
            build = {
              enable = lib.mkDefault false;
              authorizedKeys = config.users.users.ash.openssh.authorizedKeys.keys;
              fqdn = "terra.ashwalker.net";
              systems = ["x86_64-linux"];
              supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "uid-range" "kvm" "ca-derivations"];
              maxJobs = 8;
              speedFactor = 1;
            };
          };
        };
        "artemis" = {
          wireguard = {
            publicKey = "32SABdZ763omOzncqti46Zk6nL1vb9zJfDyAyc3TF0U=";
            allowedIps = genAddrs 2;
            endpoint = "artemis.ashwalker.net:${port}";
          };
        };
        "hermes" = {
          wireguard = {
            publicKey = "M3JCNlkuuhgYFN1I+JxRgBVRYjokfH+yW2PIbZBArho=";
            allowedIps = genAddrs 3;
            endpoint = "ashwalker.net:${port}";
          };
        };
        "melia" = {
          wireguard = {
            publicKey = "7qmFYeNS++O3Q+ZvSkjPharQVzYHQR5xHtAezELWE0g=";
            allowedIps = genAddrs 4;
            endpoint = "melia.ashwalker.net:${port}";
          };
        };
      };
      signal.network.wireguard.networks."wg-signal" = {
        enable = wg-signal ? privateKeyFile;
        port = 51860;
        addresses = map (addr: toString addr) (local.wireguard.addresses or []);
        dns = ["172.24.86.1" "fd24:fad3:8246::1"];
        domains =
          [
            # "~home.ashwalker.net"
          ]
          ++ (map (mcn: "~${mcn}.ashwalker.net") (attrNames machines));
        peers = foldl' (peers: name: let
          mcn = machines.${name};
        in
          if name == config.signal.machine.signalName
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
        firewall = {
          trustedInterfaces = ["wg-signal"];
          allowedUDPPorts = [wg-signal.port];
        };
      };
      nix = {
        distributedBuilds = true;
        buildMachines = foldl' (peers: name: let
          mcn = machines.${name};
          build = mcn.nix.build;
        in
          if (mcn.hostName == config.networking.hostName || !build.enable)
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

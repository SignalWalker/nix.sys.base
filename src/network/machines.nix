{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  wg = config.networking.wireguard;
  wg-signal = wg.networks."wg-signal";
  machines = config.signal.machines;

  remoteMachines = map (name: machines.${name}) (filter
    (name: name != config.signal.machine.signalName)
    (attrNames machines));

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
    signal.remoteMachines = mkOption {
      type = types.listOf types.anything;
      readOnly = true;
      default = remoteMachines;
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
                serve = {
                  enable = mkEnableOption "serve nix store from this device";
                  authorizedKeys = mkOption {
                    type = types.listOf types.singleLineStr;
                  };
                  protocol = mkOption {
                    type = types.enum ["ssh" "ssh-ng" "http" "https"];
                    default = "ssh-ng";
                  };
                  publicKey = mkOption {
                    type = types.str;
                  };
                  fqdn = mkOption {
                    type = types.str;
                    default = config.fqdn;
                  };
                  priority = mkOption {
                    type = types.int;
                    default = 0;
                  };
                  extraOptions = mkOption {
                    type = types.attrsOf types.str;
                    default = [];
                  };
                };
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
        port = toString wg-signal.netdev.port;

        nixPubKeys =
          config.users.users.ash.openssh.authorizedKeys.keys
          ++ [
            # hermes
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMXpbIhM+om7k2fjbyFAaMlnhRRbTlgIsTe+XkCTvJT6 ash@ashwalker"
          ];
      in {
        "terra" = {
          wireguard = {
            publicKey = "kFTqdNZD4LieJ+05tsELgTmAmFukny/6fzCHjixbEGc=";
            allowedIps = genAddrs 1;
            endpoint = "home.ashwalker.net:${port}";
          };
          nix = {
            serve = {
              enable = true;
              protocol = "http";
              fqdn = "nix-cache.terra.ashwalker.net";
              publicKey = "terra.ashwalker.net-1:36mAK7UNh8BAy5LkvMCtzbWpdfkvmPP6W/PhaidB6bY=";
              authorizedKeys = nixPubKeys;
              priority = 0;
              extraOptions = {
                "max-connections" = toString 8;
              };
            };
            build = {
              enable = true;
              authorizedKeys = nixPubKeys;
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
            # endpoint = "artemis.ashwalker.net:${port}";
          };
          nix = {
            # serve.enable = true;
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
            # endpoint = "melia.ashwalker.net:${port}";
          };
        };
      };
      networking.wireguard.networks."wg-signal" = {
        enable = wg-signal ? privateKeyFile;
        netdev = {
          port = 51860;
          openFirewall = true;
        };
        network = {
          addresses = map (addr: toString addr) (local.wireguard.addresses or []);
          dns = ["172.24.86.1" "fd24:fad3:8246::1"];
          domains =
            [
              # "~home.ashwalker.net"
            ]
            ++ (map (mcn: "~${mcn}.ashwalker.net") (attrNames machines));
        };
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
      networking.firewall.trustedInterfaces = ["wg-signal"];
      nix = foldl' (acc: remote: let
        build = remote.nix.build;
        serve = remote.nix.serve;

        res =
          if build.enable
          then {
            distributedBuilds = false; # FIX :: this is usually too slow to be worth it
            buildMachines = [
              {
                hostName = build.fqdn;
                protocol = "ssh-ng";
                sshUser = build.user;
                inherit (build) maxJobs supportedFeatures systems speedFactor sshKey;
              }
            ];
            settings =
              if serve.enable
              then let
                opts = serve.extraOptions // {inherit (serve) priority;};
              in {
                substituters =
                  (acc.settings.substituters or [])
                  ++ [
                    "${serve.protocol}://${serve.fqdn}" # + "?" + (std.concatStringsSep "&" (map (name: "${name}=${toString opts.${name}}") (attrNames opts))))
                  ];
                trusted-public-keys = (acc.settings.trusted-public-keys or []) ++ [serve.publicKey];
              }
              else {};
          }
          else {};
      in
        std.recursiveUpdate acc res) {}
      remoteMachines;
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
    (lib.mkIf (local.nix.serve.enable or false) (let
      serve = local.nix.serve;
    in {
      nix.sshServe = lib.mkIf (serve.protocol == "ssh" || serve.protocol == "ssh-ng") {
        enable = true;
        keys = serve.authorizedKeys;
        protocol = serve.protocol;
        write = true;
      };
    }))
  ];
  meta = {};
}

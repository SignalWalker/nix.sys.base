{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  namespaces = config.signal.network.namespaces;
in {
  options = with lib; {
    signal.network.namespaces = mkOption {
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
              enable = mkEnableOption "network namespace :: ${config.name}";
              name = mkOption {
                type = types.str;
                default = name;
              };
              systemd = {
                serviceName = mkOption {
                  type = types.str;
                  default = "netns-prepare-${config.name}";
                };
              };
              interfaces = mkOption {
                type = types.attrsOf (types.submoduleWith {
                  modules = [
                    ({
                      config,
                      lib,
                      pkgs,
                      name,
                      ...
                    }: {
                      options = with lib; {};
                      config = {};
                    })
                  ];
                });
                default = {};
              };
            };
            config = {};
          })
        ];
      });
    };
  };
  disabledModules = [];
  imports = [];
  config = lib.mkMerge ([
      {
        # from https://mth.st/blog/nixos-wireguard-netns/
        systemd.services."netns@" = let
          ip = "${pkgs.iproute}/bin/ip";
          umount = "${pkgs.utillinux}/bin/umount";
          mount = "${pkgs.utillinux}/bin/mount";
        in {
          description = "Network Namespace: %I";
          before = ["network.target"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            PrivateNetwork = true;
            ExecStart = "${pkgs.writers.writeDash "netns-up" ''
              ${ip} netns add $1
              ${umount} /var/run/netns/$1
              ${mount} --bind /proc/self/ns/net /var/run/netns/$1
            ''} %I";
            ExecStop = "${ip} netns del %I";
          };
        };
      }
    ]
    ++ (map (nsname: let
      ns = namespaces.${nsname};
      ip = "${pkgs.iproute}/bin/ip";
      iw = "${pkgs.iw}/bin/iw";
      interfaces = map (ifname: let
        iface = ns.interfaces.${ifname};
      in
        if iface.wireless
        then "${iw} phy ${iface.device} set netns name ${ns.name}"
        else "${ip} link set ${iface.device} netns ${ns.name}") (attrNames ns.interfaces);
    in (lib.mkIf ns.enable {
      systemd.services.${ns.systemd.serviceName} = {
        description = "Prepare Network Namespace: ${ns.name}";
        before = ["network.target"];
        bindsTo = ["netns@${ns.name}.service"];
        after = ["netns@${ns.name}.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.writers.writeDash "netns-prepare" ''
            ${concatStringsSep "\n" interfaces}
          ''}";
        };
      };
    })) (attrNames namespaces)));
  meta = {};
}

{
  config,
  options,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  cfg = config.signal.keyboard;
  KbdButton = {config, ...}: {
    options = {
      type = {
        type = types.enum ["keycode" "alias" "transparent" "blocking"];
        default = "keycode";
      };
      value = {
        type = types.nullOr types.str;
        default = null;
      };
    };
  };
  KbdButtonLib = {
    fromStr = optStr: let
      str =
        if optStr == null
        then ""
        else optStr;
      strStart = substring 0 1 str;
      type =
        {
          "" = "source";
          "_" = "transparent";
          "XX" = "blocking";
        }
        .str
        or (
          if strStart == "@"
          then "alias"
          else "keycode"
        );
    in {
      inherit type;
      value =
        if type == "transparent" || type == "blocking" || type == "source"
        then null
        else if type == "alias"
        then (substring 1 ((stringLength str) - 1) str)
        else str;
    };
    toStr = {
      button,
      srcKey,
      aliases ? null,
    }:
      {
        "source" = srcKey;
        "transparent" = "_";
        "blocking" = "XX";
        "alias" = assert aliases != null -> aliases ? ${button.value}; "@${button.value}";
        "keycode" = button.value;
      }
      .${button.type};
  };
  KbdLayer = with lib; types.attrsOf (types.coercedTo types.str KbdButtonLib.fromStr (types.submodule KbdButton));
  KbdLayerLib = {
    toStr = {
      name,
      layer,
      src,
      strict ? false,
      aliases ? null,
    }:
      assert !strict || (let layerCodes = attrNames (removeAttrs layer ["__default"]); in (lib.signal.set.intersect layerCodes src) == layerCodes);
        (foldl' (res: key:
          res
          + (KbdButtonLib.toStr {
            button = layer.${key} or layer.__default;
            srcKey = key;
            inherit aliases;
          })) "(deflayer ${name} "
        src)
        + " )";
  };
  KbdDevice = {config, ...}: {
    options = {
      path = mkOption {type = types.path;};
      extraGroups = mkOption {
        type = types.listOf types.str;
        default = [];
      };
      keycodes = mkOption {
        type = types.listOf types.str;
        # this is the lenovo legion 5 15ach6 keyboard
        default = import ./keyboard/templates/source/legion5;
      };
      baseLayer = mkOption {
        type = types.nullOr KbdLayer;
        default = null;
      };
    };
  };
in {
  options = with lib; {
    signal.keyboard = {
      enable = (mkEnableOption "signal keyboard config") // {default = false && pkgs ? "kmonad" && options.services ? "kmonad";};
      devices = mkOption {
        type = types.attrsOf (types.submodule KbdDevice);
        default = {};
      };
      aliases = mkOption {
        type = types.attrsOf types.str;
        default = {};
      };
      layers = mkOption {
        type = types.attrsOf KbdLayer;
        default = {};
      };
    };
  };
  imports = [];
  config = lib.mkIf (cfg.enable && ((attrNames cfg.devices) != [])) {
    signal.keyboard = {
      aliases = let
        pactl = "${pkgs.pulseaudio}/bin/pactl";
        playerctl = "${pkgs.playerctl}/bin/playerctl";
        light = "${pkgs.light}/bin/light";
        terminalCmd = "kitty";
        hkDaemon = "echo";
      in
        {
          "layer-toggle-sys" = ''(layer-toggle sys)'';
          "layer-toggle-sys-shift" = ''(layer-toggle sys-shift)'';
          "layer-toggle-sys-alt" = ''(layer-toggle sys-alt)'';
          "cmd-mute" = ''(cmd-button "${pactl} set-sink-mute @DEFAULT_SINK@ toggle")'';
          "cmd-volume-up" = ''(cmd-button "${pactl} set-sink-volume @DEFAULT_SINK@ +2%")'';
          "cmd-volume-down" = ''(cmd-button "${pactl} set-sink-volume @DEFAULT_SINK@ -2%")'';
          "cmd-mic-mute" = ''(cmd-button "${pactl} set-source-mute @DEFAULT_SOURCE@ toggle")'';
          "cmd-mic-up" = ''(cmd-button "${pactl} set-source-volume @DEFAULT_SOURCE@ +2%")'';
          "cmd-mic-down" = ''(cmd-button "${pactl} set-source-volume @DEFAULT_SOURCE@ -2%")'';
          "cmd-prev" = ''(cmd-button "${playerctl} -s previous")'';
          "cmd-play-pause" = ''(cmd-button "${playerctl} -s play-pause")'';
          "cmd-next" = ''(cmd-button "${playerctl} -s next")'';
          "cmd-brightness-up" = ''(cmd-button "${light} -A 5")'';
          "cmd-brightness-down" = ''(cmd-button "${light} -U 5")'';
          "cmd-brightness-max" = ''(cmd-button "${light} -S 100")'';
          "cmd-brightness-min" = ''(cmd-button "${light} -S 1")'';
          "cmd-lock" = ''(cmd-button "echo unimplemented: lock")'';
          "spawn-terminal" = ''(cmd-button "${terminalCmd}")'';
          "scratch-terminal" = ''(cmd-button "echo unimplemented: scratch")'';
        }
        // (foldl' (res: ws:
          res
          // {
            "wm-mv-ws${ws}" = ''(cmd-button "echo unimplemented: mv-ws${ws}")'';
            "wm-ws${ws}" = ''(cmd-button "echo unimplemented: ws${ws}")'';
          }) {} ["1" "2" "3" "4" "5" "6" "7" "8" "9"]);
      layers = {
        main = {
          __default = {type = "source";};
          "caps" = "XX";
          "lmet" = "@layer-toggle-sys";
          "mute" = "@cmd-mute";
          "volu" = "@cmd-volume-up";
          "vold" = "@cmd-volume-down";
          "brdn" = "@cmd-brightness-down";
          "brup" = "@cmd-brightness-up";
          "calc" = "@cmd-calculator";
          "pp" = "@cmd-play-pause";
          "stop" = "@cmd-stop";
          "prev" = "@cmd-prev";
          "next" = "@cmd-next";
        };
        sys = {
          __default = "_";
          "lsft" = "@layer-toggle-sys-shift";
          "lalt" = "@layer-toggle-sys-alt";
          "grv" = "@scratch-terminal";
          "ret" = "@spawn-terminal";
        };
        sys-alt = {
          __default = "_";
          "lsft" = "@layer-toggle-sys-alt-shift";
        };
        sys-shift =
          {
            __default = "_";
            "lalt" = "@layer-toggle-sys-alt-shift";
            "-" = "@wm-mv-scratch";
          }
          // (genAttrs ["1" "2" "3" "4" "5" "6" "7" "8" "9"] (ws: "@wm-mv-ws${ws}"));
        sys-alt-shift = {
          __default = "_";
        };
      };
    };
    services.kmonad = {
      enable = cfg.enable;
      keyboards = let
        aliases = concatStringsSep "\n" (foldl' (lines: name: lines ++ ["(defalias ${name} ${cfg.aliases.${name}})"]) [] (attrNames cfg.aliases));
      in
        mapAttrs (name: device: {
          inherit name;
          inherit (device) extraGroups;
          device = device.path;
          defcfg = {
            enable = true;
            compose.key = null;
            fallthrough = false;
            allowCommands = true;
          };
          config = let
            layerStrs = concatStringsSep "\n" (map (layerName:
              KbdLayerLib.toStr {
                layer = cfg.layers.${layerName};
                name = layerName;
                src = device.keycodes;
                inherit (cfg) aliases;
              }) (attrNames cfg.layers));
          in ''
            (defsrc
              ${concatStringsSep " " device.keycodes}
            )
            ${aliases}
            ${layerStrs}
          '';
        })
        cfg.deviceMap;
      extraArgs = [];
    };
  };
}

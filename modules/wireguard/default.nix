{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (pkgs) liminix;
in
{
  options = {
    system.service.wireguard = mkOption {
      type = liminix.lib.types.serviceDefn;
    };
  };
  config = {
    kernel.config = {
       WIREGUARD = "y";
    };
    system.service.wireguard = config.system.callService ./wireguard.nix {
      ifname = mkOption {
        type = types.str;
        description = "wireguard interface name to create";
      };
      config = mkOption {
        type = types.pathInStore;
        description = "path to configuration file";
      };
    };
  };
}

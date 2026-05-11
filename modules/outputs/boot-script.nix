{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    ;
  inherit (pkgs.pseudofile) dir symlink;
  cfg = config.boot.loader.script;
  o = config.system.outputs;
  cmdline = builtins.concatStringsSep " " config.boot.commandLine;
  arch = pkgs.stdenv.hostPlatform.linuxArch;
in
{
  options.boot.loader.script.enable = mkEnableOption "boot.scr in /boot";

  config = mkIf cfg.enable {
    system.outputs.bootfiles = pkgs.preinit {
      inherit config;
      nativeBuildInputs = with pkgs.pkgsBuildBuild; [
        ubootTools
      ];
      installPhase = ''
        cat > boot.cmd <<EOF
        setenv bootargs ${cmdline} init=$out/bin/preinit
        ubifsload \''${loadaddr} ${o.uimage}
        bootm \''${loadaddr}
        EOF
        mkimage -c none -A ${arch} -T script -d boot.cmd $out/boot.scr
      '';
    };
  };
}

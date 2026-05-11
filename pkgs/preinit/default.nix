{ stdenv, gdb, lib, closureInfo, writeText }:
{ config,
  installPhase ? "",
  nativeBuildInputs ? [],
}:
let
  inherit (lib.attrsets) mapAttrsToList;
  escaped =
    msg: builtins.replaceStrings [ "\n" "=" "\"" "$" ] [ "\\x0a" "\\x3d" "\\x22" "\\x24" ] msg;

  visit =
    prefix: attrset:
    let
      makeFile =
        prefix: filename:
        {
          type ? "f",
          mode ? null,
          target ? null,
          contents ? null,
          file ? null,
          major ? null,
          minor ? null,
          uid ? 0,
          gid ? 0,
        }:
        let
          pathname = "${prefix}/${filename}";
          qpathname = builtins.toJSON pathname;
          mode' = if mode != null then mode else (if type == "d" then "0755" else "0644");
          cmds = {
            "f" = "PRINTFILE(${qpathname}, ${mode'}, ${builtins.toJSON (escaped file)});";
            "d" =
              "MKDIR(${qpathname}, ${mode'});\n" + (builtins.concatStringsSep "\n" (visit pathname contents));
            "c" = "MKNOD_C(${qpathname}, ${mode'}, ${major}, ${minor});";
            "b" = "MKNOD_B(${qpathname}, ${mode'}, ${major}, ${minor});";
            "s" = "LN_S(${builtins.toJSON target}, ${qpathname});";
            "l" = "LN(${builtins.toJSON target}, ${qpathname})";
            "i" = "MKNOD_P(${qpathname}, ${mode'});";
          };
          cmd = cmds.${type};
          chown =
            if uid > 0 || gid > 0 then "\nCHOWN(${qpathname},${toString uid},${toString gid});\n" else "";
        in
        "unlink(${qpathname}); ${cmd} ${chown}";
    in
    mapAttrsToList (makeFile prefix) attrset;
  activateScript = writeText "activate.c" ''
    #include "activate.h"
    #include "print_file.h"

    #include <sys/stat.h>
    #include <sys/sysmacros.h>
    #include <unistd.h>

    #define PRINTFILE(path, mode, text) print_file(path, (mode_t) mode, text)
    #define MKDIR(path, mode) mkdir(path, mode)
    #define MKNOD_C(path, mode, major,minor) mknod(path, mode | S_IFCHR, makedev(major, minor))
    #define MKNOD_B(path, mode, major,minor) mknod(path, mode | S_IFBLK, makedev(major, minor))
    #define LN_S(target, path) (void)symlink(target, path)
    #define LN(target, path) link(target, path)
    #define MKNOD_P(path, mode) mkfifo(path, mode)
    #define CHOWN(path, uid, gid) chown(path, uid, gid)

    void activate() {
      ${(builtins.concatStringsSep "\n" (visit "." config.filesystem.contents))}
      LN_S(BOOTPATH, "boot");
    }

    /*
     * Ensure that the dependencies of installPhase are added to the activateScript's closure.
     */
    #if 0
    ${installPhase}
    #endif
  '';
  closure = closureInfo { rootPaths = activateScript; };
in
stdenv.mkDerivation {
  inherit nativeBuildInputs;
  name = "preinit";
  src = ./.;

  #  NIX_DEBUG=2;
  hardeningDisable = [ "all" ];

  postConfigure = ''
    cp ${activateScript} activate.c
  '';
  makeFlags = [ "CFLAGS=-DBOOTPATH=\\\"${placeholder "out"}\\\"" ];
  stripAllList = [ "bin" ];
  installPhase = ''
    mkdir -p $out/bin $out/etc
    cp preinit $out/bin
    echo $out > $out/etc/nix-store-paths
    cat ${closure}/store-paths >> $out/etc/nix-store-paths
    ${installPhase}
  '';
}

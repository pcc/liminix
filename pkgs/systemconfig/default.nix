# The ideal is that a Liminix system can boot with only the files in
# /nix/store.  This package generates a small program that is run at early
# boot (from the initramfs) to populate directories such as /etc,
# /bin, /home according to whatever the configuration says
# they should contain

{
  writeText,
  writeFennel,
  buildPackages,
  lib,
  s6-init-bin,
  closureInfo,
  stdenv,
}:
stdenv.mkDerivation {
  name = "system-configuration";
  src = ./.;

  CFLAGS = "-Os";

  installPhase = ''
    mkdir -p $out/bin $out/etc
    ln -s ${s6-init-bin}/bin/init $out/bin/init
    cp -p ${writeFennel "restart-services" { } ./restart-services.fnl} $out/bin/restart-services
    cat > $out/bin/install <<EOF
    #!/bin/sh -e
    prefix=\''${1-/}
    src=\''${prefix}$out
    dest=\$prefix
    ${
      # if we are running on a normal mounted system then
      # the actual device root is mounted on /persist
      # and /nix is bind mounted from /persist/nix
      # (see the code in preinit). So we need to check for this
      # case otherwise we will install into a ramfs/rootfs
      ""
    }
    if test -d \$dest/persist; then dest=\$dest/persist; fi
    cp -v -fP \$src/bin/* \$src/etc/* \$dest
    ${
      if attrset ? boot then
        ''
          (cd \$dest
           test -d boot || mkdir boot
           cd boot
           cp ../${lib.strings.removePrefix "/" attrset.boot.target}/* .
           sync; sync
          )
        ''
      else
        ""
    }
    EOF
    chmod +x $out/bin/install
  '';
}

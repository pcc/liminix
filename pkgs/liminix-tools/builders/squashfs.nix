{
  buildPackages,
  callPackage,
  nixpkgs,
  pseudofile,
  runCommand,
  writeText,
}:
bootfiles:
let
  storefs = callPackage "${nixpkgs}/nixos/lib/make-squashfs.nix" {
    storeContents = [ bootfiles ];
  };
in
runCommand "frob-squashfs"
  {
    nativeBuildInputs = with buildPackages; [
      squashfsTools
      qprint
    ];
  }
  ''
    cp ${storefs} ./store.img
    chmod +w store.img
    mksquashfs - store.img -exit-on-error -no-recovery -quiet -no-progress  -root-becomes store -p "/ d 0755 0 0"
    mksquashfs - store.img -exit-on-error -no-recovery -quiet -no-progress  -root-becomes nix  -p "/ d 0755 0 0"
    cp store.img $out
  ''

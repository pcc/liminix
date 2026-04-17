{
  liminix,
  pkgs,
}:
{
  ifname,
  config,
}:
let
  inherit (liminix.services) oneshot;
  wg = "${pkgs.wireguard-tools}/bin/wg";
in
oneshot rec {
  name = "${ifname}.link";
  up = ''
    ip link add dev ${ifname} type wireguard
    ${wg} setconf ${ifname} ${config}
    ip link set up dev ${ifname}
    (in_outputs ${name}
     echo ${ifname} > ifname
    )
  '';
  down = ''
    ip link del dev ${ifname}
  '';
}

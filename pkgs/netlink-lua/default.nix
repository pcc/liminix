{
  lua,
  fetchFromGitHub,
  libmnl,
}:
let
  pname = "netlink";
in
lua.pkgs.buildLuaPackage {
  inherit pname;
  version = "0.1.1-1";

  buildInputs = [ libmnl ];

  src = fetchFromGitHub {
    repo = "lua-netlink";
    owner = "pcc";
    rev = "48408e2cc27d704c3e281880b1001c57693ad24d";
    hash = "sha256-z4EK2sKxTdDShhD8e5Z6IeZyQduwOqbXeXmkMhsOTIU=";
  };

  buildPhase = "$CC -shared -l mnl -l lua -DVERSION=\\\"1.1.0\\\" -o netlink.so src/*.c";

  installPhase = ''
    mkdir -p "$out/lib/lua/${lua.luaversion}"
    cp  netlink.so "$out/lib/lua/${lua.luaversion}/"
  '';

}

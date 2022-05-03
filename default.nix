{stdenv, zig, ...}:

stdenv.mkDerivation {
  name = "wkSwitch";
  buildInputs = [ zig ];
  src = builtins.path { path = ./.; name = "wkSwitch"; };
  hardeningDisable = [ "all" ];

  XDG_CACHE_HOME = "xdg_cache";
}

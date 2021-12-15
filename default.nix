{stdenv, musl, ...}:

stdenv.mkDerivation {
  name = "wkSwitch";
  buildInputs = [ musl ];
  src = builtins.path { path = ./.; name = "wkSwitch"; };
}

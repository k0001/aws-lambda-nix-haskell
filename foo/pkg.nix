{ mkDerivation, base, stdenv }:
mkDerivation {
  pname = "foo";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [ base ];
  license = stdenv.lib.licenses.unfree;
}

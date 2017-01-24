let pkgs = import <nixpkgs> {};
in pkgs.runCommand "dummy" {
  buildInputs = [ (pkgs.haskell.packages.ghc802.ghcWithPackages (hs: [ hs.cabal-install ])) ];
} ":"

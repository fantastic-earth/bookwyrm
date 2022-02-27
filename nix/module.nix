{pkgs, ...}@args:
  import ./moduleInner.nix (args // (
    let 
      pinnedPkgs = import (pkgs.fetchFromGitHub {
          owner = "NixOS";
          repo = "nixpkgs";
          rev = "7f9b6e2babf232412682c09e57ed666d8f84ac2d";
          sha256 = "sha256-4va4MvJ076XyPp5h8sm5eMQvCrJ6yZAbBmyw95dGyw4=";
        }) { 
          # we need to inherit config to propagate allowUnfree settings (which
          # are needed for bookwyrm)
          inherit (pkgs) system config; 
        };
    in { bookwyrm = pinnedPkgs.callPackage ./default.nix { };}))
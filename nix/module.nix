{pkgs, ...}@args:
  import ./moduleInner.nix (args // (
    let 
      pinnedPkgs = import (pkgs.fetchFromGitHub {
          owner = "NixOS";
          repo = "nixpkgs";
          rev = "ce8cbe3c01fd8ee2de526ccd84bbf9b82397a510";
          sha256 = "sha256-u69opCeHUx3CsdIerD0wVSR+DjfDQjnztObqfk9Trqc=";
        }) { 
          # we need to inherit config to propagate allowUnfree settings (which
          # are needed for bookwyrm)
          inherit (pkgs) system config; 
        };
    in { bookwyrm = pinnedPkgs.callPackage ./default.nix { };}))
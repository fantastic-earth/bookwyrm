{pkgs, ...}@args:
  import ./moduleInner.nix (args // (
    let 
      pinnedPkgs = import (pkgs.fetchFromGitHub {
          owner = "NixOS";
          repo = "nixpkgs";
          rev = "5aaed40d22f0d9376330b6fa413223435ad6fee5";
          sha256 = "sha256-m71b7MgMh9FDv4MnI5sg9MiBVW6DhE1zq+d/KlLWSC8=";
        }) { 
          # we need to inherit config to propagate allowUnfree settings (which
          # are need for bookwyrm)
          inherit (pkgs) system config; 
        };
    in { bookwyrm = pinnedPkgs.callPackage ./default.nix { };}))
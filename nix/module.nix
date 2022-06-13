{pkgs, ...}@args:
  import ./moduleInner.nix (args // (
    let 
      pinnedPkgs = import (pkgs.fetchFromGitHub {
          owner = "NixOS";
          repo = "nixpkgs";
          rev = "914ef51ffa88d9b386c71bdc88bffc5273c08ada";
          sha256 = "sha256-A+oT+aQGhW5lXy8H0cqBLsYtgcnT5glmGOXWQDcGw6I=";
        }) { 
          # we need to inherit config to propagate allowUnfree settings (which
          # are needed for bookwyrm)
          inherit (pkgs) system config; 
        };
    in { bookwyrm = pinnedPkgs.callPackage ./default.nix { };}))
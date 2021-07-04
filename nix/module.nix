{pkgs, ...}@args:
  import ./moduleInner.nix (args // (
    let 
      pinnedPkgs = import (pkgs.fetchFromGitHub {
          owner = "NixOS";
          repo = "nixpkgs";
          rev = "09c38c29f2c719cd76ca17a596c2fdac9e186ceb";
          sha256 = "0i6kcs0zxwfaflcg6wfkwcinfnilkxlb6ad29v01bkhg6asl6ihf";
        }) { 
          # we need to inherit config to propagate allowUnfree settings (which
          # are need for bookwyrm)
          inherit (pkgs) system config; 
        };
    in { bookwyrm = pinnedPkgs.callPackage ./default.nix { };}))
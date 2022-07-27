{pkgs, ...}@args:
  import ./moduleInner.nix (args // ({ bookwyrm = pkgs.callPackage ./default.nix { };}))
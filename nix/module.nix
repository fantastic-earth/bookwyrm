{config, ...}: {
    imports = [ ./moduleInner.nix ];
    nixpkgs.overlays = [
      (final: prev: {
        bookwyrm = prev.callPackage ./default.nix { };
      })
    ];
  }

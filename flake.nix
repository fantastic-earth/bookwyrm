{
  description = "Bookwyrm decentralized reading and reviewing server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let 
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        packages.bookwyrm = pkgs.callPackage ./nix/default.nix { };

        defaultPackage = self.packages.${system}.bookwyrm;
      }
    ) // 
    {
      nixosModule = ./nix/module.nix;
    };
}

# Bookwyrm Nix changelog
This covers changes to the Nix and NixOS packaging of Bookwyrm, not changes to Bookwyrm core itself.

## 0.7.0-nix1
* Updated to upstream version 0.7.0. See <https://github.com/bookwyrm-social/bookwyrm/releases/tag/v0.7.0>

## 0.6.6-nix1
* Updated to upstream version 0.6.6. See <https://github.com/bookwyrm-social/bookwyrm/releases/tag/v0.6.6>

## 0.6.5-nix3
* The flake now outputs an overlay with `pkgs.bookwyrm`.
* The NixOS module now adds an overlay, and builds Bookwyrm through overlay. `services.bookwyrm.package` is now exposed to allow changing the Bookwyrm package used, so it is possible to pass the flake's `defaultPackage` down to it if so desired. 

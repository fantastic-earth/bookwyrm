# Bookwyrm Nix changelog
This covers changes to the Nix and NixOS packaging of Bookwyrm, not changes to Bookwyrm core itself.

## 0.6.5-nix3
* The flake now outputs an overlay with `pkgs.bookwyrm`.
* The NixOS module now adds an overlay, and builds Bookwyrm through overlay. `services.bookwyrm.package` is now exposed to allow changing the Bookwyrm package used, so it is possible to pass the flake's `defaultPackage` down to it if so desired. 

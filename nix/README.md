# Nix module for Bookwyrm

This is a Nix module for Boookwyrm, allowing for deployment of Bookwyrm natively on NixOS without Docker. It has been used in production at <https://books.underscore.world> without critical issues, but is also rough around the edges. 

## How to use

### Non-flake use
[Niv](https://github.com/nmattia/niv) can be used to include the module in a NixOS configuration. In `/etc/nixos` (or, if permissions are a problem, somewhere in your home directory before copying to `/etc/nixos` later) do:

```shellsession
$ niv init
$ niv add DeeUnderscore/bookwyrm -b nix 
```

Now, the module can be imported as such:

```nix
# /etc/nix/configuration.nix
{ config, pkgs, lib, ... }:
{
  imports =
    [ 
      ./hardware-configuration.nix

      # … 

      "${(import ../../nix/sources.nix).bookwyrm}/nix/module.nix"
    ];

    # …
}
```

### Flake use 
If you are configuring NixOS with flakes, you can add `github:DeeUnderscore/bookwyrm/nix` as an input. Bookwyrm is available under the `defaultPackage` output, an overlay (adding `pkgs.bookwyrm`)is available under the `overlay` output, and the NixOS module is available under the `nixosModule` output. The NixOS module will enable the overlay, and use Bookwyrm built against the configuration's Nixpkgs. Example configuration:

```nix
# flake.nix
{
  inputs = {
    bookwyrm.url = "github:DeeUnderscore/bookwyrm/nix";
  };
  outputs = {self, nixpkgs, bookwyrm, ...}:
  {
    nixosConfigurations.example = nixpkgs.lib.nixosSystem {
      # …
      modules = [ 
        ./configuration.nix
        inputs.bookwyrm.nixosModule
       ];
      # …
    };
  };
}
```

### Configuring
Bookwyrm can be enabled with a configuration similar to this: 

```nix
  services.bookwyrm = {
    enable = true;
    secretKey = "verysecret123";
    domain = "bookwyrm.example.com";
    allowedHosts = [ "bookwyrm.example.com" ];
    flowerArgs = [ "--port=8888" ];
    database = {
      user = "bookwyrm";
      database = "bookwyrm";
    };
    activityRedis = {
      unixSocket = "/run/redis/redis.sock";
    };
    celeryRedis = {
      unixSocket = "/run/redis/redis.sock";
    };

    email = {
      host = "127.0.0.1";
      port = 1025;
      useTLS = false;

      user = "bookwyrm";
      password = "password123";
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "bookwyrm"
  ];
```

For detailed list options see the `module.nix` source file (there is currently no generated documentation for them). If working with a secret vault (like [sops-nix](https://github.com/Mic92/sops-nix)), secrets can be supplied as file paths instead (for example `services.bookwyrm.secretKeyFile`), per the usual Nixpkgs convention. 

`services.bookwyrm.activityRedis.createLocally` and `services.bookwyrm.celeryRedis.createLocally`, when enabled, will set up separate instances of Redis, and set up Bookwyrm to connect to each via a Unix domain socket. 

The module currently does not set up Nginx, so you will have to do it yourself, including providing HTTP Basic Authentication for Flower, which otherwise has no inbuilt user accounts. An example, which assumes your Flower was configured with `flowerArgs = [ "--unix_socket=/run/bookwyrm/bookwyrm-flower.sock" ];`:

```nix
  services.nginx.virtualHosts."bookwyrm.example.com" = {
    serverName = "bookwyrm.example.com";
    root = "/var/empty";
    locations."/" = {
      proxyPass = "http://unix:/run/bookwyrm/bookwyrm.sock";
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      ''; 
    };
    locations."/static/" = {
      alias = "/var/lib/bookwyrm/static/";
    };

    locations."/images/" = {
      alias = "/var/lib/bookwyrm/images/";
    };
  };
  services.nginx.virtualHosts."bookwyrm-flower" = {
    serverName = "flower.bookwyrm.example.com";
    basicAuthFile = "/var/lib/bookwyrm/htpasswd"; # example way of generating: `echo your_username:$(mkpasswd -m sha512crypt)`
    root = "/var/empty";
    locations."/" = {
      proxyPass = "http://unix:/run/bookwyrm/bookwyrm-flower.sock";
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      ''; 
    };
  };
```

### Imperative setup

> **Note** There are no tests for the instructions in this section. They may be out of date. 

On first run, you will have to initialize the Bookwyrm database: 

```shellsession
# bookwyrm-manage initdb
```

Additionally, you may have to use a Postgresql superuser to enable some extensions which Bookwyrm expects, and cannot enable itself:

```shellsession 
# sudo -u postgres psql -d bookwyrm
bookwyrm=# CREATE EXTENSION IF NOT EXISTS citext;
bookwyrm=# CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

## Running

Enabling this module provides a `bookwyrm-manage` executable in PATH, equivalent to running Bookwyrm's `manage.py`; see [Django documentation on manage.py](https://docs.djangoproject.com/en/3.1/ref/django-admin/) for some details. Note that database migrations and static content populating are done automatically on startup and do not have to be done manually.

The Systemd units are `bookwyrm.service`, `bookwyrm-celery.service`, and `bookwyrm-flower.service`. If you want to follow them with `journalctl` for troubleshooting purposes, you can do: `journalctl -efu bookwyrm-flower -u bookwyrm-celery -u bookwyrm`. The target for the Bookwyrm services is `bookwyrm.target`: `systemctl list-dependencies bookwyrm.target`.

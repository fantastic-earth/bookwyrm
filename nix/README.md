# Nix module for Bookwyrm

This is a Nix module for Boookwyrm, allowing for deployment of Bookwyrm natively on NixOS, without Docker. 

`module.nix` can be used as an import in `/etc/nixos/configuration.nix`, but has not yet been tested in production. 

## How to use

### Importing the module
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

### Configuring
Bookwyrm can be enabled with a configuration similar to this: 

```nix
  services.bookwyrm = {
    enable = true;
    secretKey = "verysecret123";
    domain = "bookwyrm.example.com";
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
```

For detailed list options see the `module.nix` source file (there is currently no generated documentation for them). If working with a secret vault (like [sops-nix](https://github.com/Mic92/sops-nix)), secrets can be supplied as file paths instead (for example `services.bookwyrm.secretKeyPath`), per the usual nixpkgs convention. 

`services.bookwyrm.activityRedis.createLocally` and `services.bookwyrm.celeryRedis.createLocally` will start up Redis locally, and connect to it over TCP (the default for Redis on NixOS 20.09 does not provide a unix socket). If Redis is configured to listen on a socket, `services.bookwyrm.activityRedis.unixSocket` and `services.bookwyrm.celeryRedis.unixSocket` can be used instead. 

The Docker deployment of Bookwyrm uses two separate containers of Redis, while this Nix module uses the same instance of Redis for both. NixOS 20.09 does not provide a simple way to run multiple instances of Redis, but you could use [NixOS containers](https://nixos.org/manual/nixos/stable/#ch-containers) to imitate the Docker setup. 

The module currently does not set up nginx, so you will have to do it yourself, including providing HTTP Basic Authentication for Flower, which otherwise has no inbuilt user accounts. An example:

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
    basicAuthFile = "/var/lib/bookwyrm/htpasswd"; # generate manually with htpasswd from pkgs.apacheHttpd
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

Enabling this module provides a `bookwyrm-manage` executable in PATH, equivalent to running Bookwyrm's `manage.py`; see [Django documentation on manage.py](https://docs.djangoproject.com/en/3.1/ref/django-admin/) for some details. Note that database migrations and static content populating are done automatically on startup and do not have to be done manually

The Systemd units are `bookwyrm.service`, `bookwyrm-celery.service`, and `bookwyrm-flower.service`. If you want to follow them with `journalctl` for troubleshooting purposes, you can do: `journalctl -efu bookwyrm-flower -u bookwyrm-celery -u bookwyrm`. The target for the Bookwyrm services is `bookwyrm.target`: `systemctl list-dependencies bookwyrm.target`.

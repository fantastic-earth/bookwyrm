{ stdenv
, lib
, poetry2nix
, gettext
, symlinkJoin
, pkgs
}:
let
  bookwyrmSource = ./..;
  poetryApp = poetry2nix.mkPoetryApplication rec {
    projectDir = bookwyrmSource;
    src = bookwyrmSource;

    # overrides are related to deps not getting the build systems they need
    # related poetry2nix issues:
    # https://github.com/nix-community/poetry2nix/issues/218
    # https://github.com/nix-community/poetry2nix/issues/568

    overrides = (poetry2nix.overrides.withDefaults (final: prev: {
      typing-extensions = prev.typing-extensions.overridePythonAttrs (
        prevAttrs: {
          buildInputs = (prevAttrs.buildInputs or []) ++ [ final.flit-core ];
        }
      );

      click-didyoumean = prev.click-didyoumean.overridePythonAttrs (
        prevAttrs: {
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [ final.poetry-core ];
        }
      );

      django-sass-processor = prev.django-sass-processor.overridePythonAttrs (
        prevAttrs: {
          format = "setuptools";
        }
      );

      django-imagekit = prev.django-imagekit.overridePythonAttrs (
        prevAttrs: {
          format = "setuptools";
        }
      );

      pathspec = prev.pathspec.overridePythonAttrs (
        prevAttrs: {
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [ final.flit-core ];
        }
      );

      iniconfig = prev.iniconfig.overridePythonAttrs (
        prevAttrs: {
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [ final.hatchling ];
        }
      );

      humanize = prev.humanize.overridePythonAttrs (
        prevAttrs: {
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [
            final.hatchling
            final.hatch-vcs
          ];
        }
      );

      kombu = prev.kombu.overridePythonAttrs (
        prevAttrs: {
          format = "setuptools";

          # https://github.com/celery/kombu/pull/1652
          patchPhase = ''
            substituteInPlace requirements/test.txt \
              --replace 'pytz>dev' 'pytz'
          '';
        }
      );

      attrs = prev.attrs.overridePythonAttrs (
        prevAttrs: {
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [
            final.hatchling
            final.hatch-vcs
            final.hatch-fancy-pypi-readme
          ];
        }
      );

      sqlparse = prev.sqlparse.overridePythonAttrs (
        prevAttrs: {
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [ final.flit-core ];
        }
      );

      opentelemetry-exporter-otlp-proto-grpc = prev.opentelemetry-exporter-otlp-proto-grpc.overridePythonAttrs (
        prevAttrs: {
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [ final.hatchling ];
        }
      );

      opentelemetry-instrumentation-celery = prev.opentelemetry-instrumentation-celery.overridePythonAttrs (
        prevAttrs: {
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [ final.hatchling ];
        }
      );

      opentelemetry-instrumentation-dbapi = prev.opentelemetry-instrumentation-dbapi.overridePythonAttrs (
        prevAttrs: {
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [ final.hatchling ];
        }
      );

      opentelemetry-instrumentation-psycopg2 = prev.opentelemetry-instrumentation-psycopg2.overridePythonAttrs (
        prevAttrs: {
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [ final.hatchling ];
        }
      );

      opentelemetry-util-http = prev.opentelemetry-util-http.overridePythonAttrs (
        prevAttrs: {
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [ final.hatchling ];
        }
      );

      opentelemetry-instrumentation-wsgi = prev.opentelemetry-instrumentation-wsgi.overridePythonAttrs (
        prevAttrs: {
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [ final.hatchling ];
        }
      );

      opentelemetry-instrumentation-django = prev.opentelemetry-instrumentation-django.overridePythonAttrs (
        prevAttrs: {
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [ final.hatchling ];
        }
      );

      pillow = prev.pillow.overridePythonAttrs (
        prevAttrs: {
          patches = (prevAttrs.patches or []) ++ [
            # https://github.com/python-pillow/Pillow/pull/7069
            (pkgs.fetchpatch {
              url = "https://github.com/python-pillow/Pillow/commit/d94239ae3d21d8ae03f5120228dc8225faa99bac.patch";
              hash = "sha256-fTBfXZPefZnOX5AO3lgZ8ya9G+JW2GDl1V/2cdFritk=";
            })
          ];
        }
      );
    })) ++ [ (final: prev: {
      # current poetry2nix does not have cargo hashes for cryptography 41, but it
      # does override it. We need to append this overlay here to ensure it goes
      # after the defaults.
      cryptography = prev.cryptography.overridePythonAttrs (
        prevAttrs: {
          cargoDeps = pkgs.rustPlatform.fetchCargoTarball {
            inherit (prevAttrs) src;
            name = "${prevAttrs.pname}-${prevAttrs.version}";
            sourceRoot = "${prevAttrs.pname}-${prevAttrs.version}/${prevAttrs.cargoRoot}";
            sha256 = "sha256-38q81vRf8QHR8lFRM2KbH7Ng5nY7nmtWRMoPWS9VO/U=";
          };
        }
      );
    }) ];

    meta = with lib; {
      homepage = "https://bookwyrm.social/";
      description = "Decentralized social reading and reviewing platform server";
      license = {
        fullName = "The Anti-Capitalist Software License";
        url = "https://anticapitalist.software/";
        free = false;
      };
    };
  };
  updateScripts = stdenv.mkDerivation {
    name = "bookwyrm-update-scripts";
    src = bookwyrmSource;

    dontBuild = true;

    buildInputs = [
      poetryApp.dependencyEnv
    ];

    installPhase = ''
      mkdir -p $out/libexec/bookwyrm

      patchShebangs update.sh manage.py

      cp ./manage.py $out/libexec/bookwyrm

      cp ./update.sh $out/libexec/bookwyrm/
      cp -r updates $out/libexec/bookwyrm/
    '';

    fixupPhase = ''
      substituteInPlace $out/libexec/bookwyrm/update.sh \
        --replace './bw-dev runweb python manage.py' "${poetryApp.dependencyEnv}/bin/python $out/libexec/bookwyrm/manage.py" \
        --replace 'ls -A updates/' "ls -A $out/libexec/bookwyrm/updates" \
        --replace './updates/$version' "$out/libexec/bookwyrm/updates/"'$version'

      for f in $out/libexec/bookwyrm/updates/*; do
        substituteInPlace $f \
          --replace './bw-dev migrate' "${poetryApp.dependencyEnv}/bin/python $out/libexec/bookwyrm/manage.py migrate"
      done
    '';
  };
# The update scripts need to be able to run manage.py under the Bookwyrm
# environment, but we don't have access to dependencyEnv when building
# poetryApp. As an ugly workaround, we patch the scripts with the right paths
# separately, and symlinkJoin them with the original environment.
in symlinkJoin {
  name = "bookwyrm";
  paths = [
    poetryApp.dependencyEnv
    updateScripts
  ];
}

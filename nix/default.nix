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

      opentelemetry-instrumentation-celery = prev.opentelemetry-instrumentation-celery.overridePythonAttrs (
        prevAttrs: {
          format = "pyproject";
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [ final.hatchling ];
        }
      );

      opentelemetry-instrumentation-dbapi = prev.opentelemetry-instrumentation-dbapi.overridePythonAttrs (
        prevAttrs: {
          format = "pyproject";
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [ final.hatchling ];
        }
      );

      opentelemetry-instrumentation-psycopg2 = prev.opentelemetry-instrumentation-psycopg2.overridePythonAttrs (
        prevAttrs: {
          format = "pyproject";
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [ final.hatchling ];
        }
      );

      bw-file-resubmit = prev.bw-file-resubmit.overridePythonAttrs (
        prevAttrs: {
          format = "pyproject";
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [ final.setuptools-scm ];
        }
      );

      marshmallow =  prev.marshmallow.overridePythonAttrs (
        prevAttrs: {
          format = "pyproject";
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [ final.flit-core ];
        }
      );

      django-pgtrigger = prev.django-pgtrigger.overridePythonAttrs (
        prevAttrs: {
          format = "pyproject";
          nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [ final.poetry-core ];
        }
      );
    })) ++ [ (final: prev: {
      # current poetry2nix does not have cargo hashes for the locked versu of 
      # cryptography but it does override it. We need to append this overlay 
      # here to ensure it goes after the defaults.
      cryptography = prev.cryptography.overridePythonAttrs (
        prevAttrs: {
          cargoDeps = pkgs.rustPlatform.fetchCargoTarball {
            inherit (prevAttrs) src;
            name = "${prevAttrs.pname}-${prevAttrs.version}";
            sourceRoot = "${prevAttrs.pname}-${prevAttrs.version}/${prevAttrs.cargoRoot}";
            sha256 = "sha256-Pw3ftpcDMfZr/w6US5fnnyPVsFSB9+BuIKazDocYjTU="; #v42.0.5
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

{ stdenv
, lib
, poetry2nix
, python39
, gettext
, symlinkJoin
}:
let 
  bookwyrmSource = ./..;
  poetryApp = poetry2nix.mkPoetryApplication rec {
    projectDir = bookwyrmSource;
    src = bookwyrmSource;
    python = python39;

    # typing-extensions needs flit
    # see https://github.com/nix-community/poetry2nix/issues/218
    overrides = poetry2nix.overrides.withDefaults (final: prev: {
      typing-extensions = prev.typing-extensions.overridePythonAttrs (
        prevAttrs: {
          buildInputs = (prevAttrs.buildInputs or []) ++ [ final.flit-core ];
        }
      );
    });

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

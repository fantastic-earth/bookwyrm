{ stdenv
, lib
, poetry2nix
, python39
, gettext
}:
let 
  bookwyrmSource = ./..;
  poetryApp = poetry2nix.mkPoetryApplication rec {
    projectDir = bookwyrmSource;
    src = bookwyrmSource;
    python = python39;

    postInstall = ''
      mkdir -p $out/
      
      cp ./manage.py $out/
    '';

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
in poetryApp.dependencyEnv

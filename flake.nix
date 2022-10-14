{
  # Idea: 
  # [Build LaTeX Documents Reproducibly](https://flyx.org/nix-flakes-latex/)
  #
  # Another inspiration:
  # https://github.com/ysndr/cv
  #
  # Yet another template:
  # https://github.com/joshniemela/LatexNix
  #
  description = "LaTeX CV";
  inputs = { flake-utils.url = "github:numtide/flake-utils"; };

  outputs = { self, nixpkgs, flake-utils }:
    with flake-utils.lib;
    eachSystem allSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        tex = pkgs.texlive.combine {
          inherit (pkgs.texlive)
            scheme-small latexmk pgf nicematrix fontspec montserrat xkeyval ly1
            xstring xifthen moresize fontawesome paracol geometry fancyhdr
            hyperref ifmtarg transparent fontawesome5;
        };
        fonts = pkgs.makeFontsConf {
          fontDirectories = [
            "${pkgs.montserrat}/share/fonts"
            "${pkgs.alegreya-sans}/share/fonts"
            "${pkgs.font-awesome}/share/fonts"
          ];
        };
        texvars = (pkgs.lib.strings.fileContents ./secrets.txt);
        #buildCV = texvars:
          
      in rec {
        packages = {
          cv = pkgs.stdenvNoCC.mkDerivation rec {
            name = "curriculum-vitae";
            src = self;
            nativeBuildInputs = [ tex ];

            phases = [ "unpackPhase" "buildPhase" "installPhase" ];

            FONTCONFIG_FILE = fonts;

            # pin pdf timestamp
            SOURCE_DATE_EPOCH = "${toString self.lastModified}";

            buildPhase = ''
              echo '${texvars}'
              xelatex -interaction=nonstopmode "${texvars}" "\input{cv}"
            '';

            installPhase = ''
              cp cv.pdf $out
            '';
          };
        };
        defaultPackage = packages.cv;
        #defaultApps =
        devShell = with pkgs;
          mkShell {
            name = "LaTeX";

            nativeBuildInputs = [ tex texstudio ];

            shellHook = "exec fish";

          };
      });
}

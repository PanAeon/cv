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
  # Example of font embedding:
  # https://wellquite.org/posts/latex_fonts_and_nixos/
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

        source = ./cv.tex;
        qr-code = ./qrcode.png;

        build-cv = pkgs.writeShellScriptBin "build-cv" ''
           export FONTCONFIG_FILE=${fonts}
           export SOURCE_DATE_EPOCH=${toString self.lastModified}
           ${tex}/bin/xelatex -jobname=cv -interaction=nonstopmode "''$1" "\input{''$2}"
           echo "done"
        '';
        # build cv in the current directory
        # pass variables from personal-info to xelatex
        cv = pkgs.writeShellScriptBin "cv" ''
            if (($# < 1))
            then
                texvars=""
                if test -f ./personal-info.txt; then
                    texvars=`cat ./personal-info.txt`
                fi
                ${build-cv}/bin/build-cv "$texvars" ${source}
            elif (($# < 2))
            then
                texvars=`cat $1`
                echo "$texvars"
                ${build-cv}/bin/build-cv  "$texvars" ${source}
            else
                texvars=`cat $2`
                ${build-cv}/bin/build-cv "$texvars" $1
            fi
        '';
      in rec {
        packages = {
          build-cv = build-cv;
          cv = pkgs.stdenvNoCC.mkDerivation rec {
            name = "curriculum-vitae";
            src = self;

            phases = [ "buildPhase" "installPhase" ];

            buildPhase = ''
              cp ${qr-code} qrcode.png
              ${build-cv}/bin/build-cv "" ${source}
            '';

            installPhase = ''
              cp cv.pdf $out
            '';
          };
        };
        defaultPackage = packages.cv;
        defaultApp = cv;
        devShell = with pkgs;
          mkShell {
            name = "LaTeX";

            nativeBuildInputs = [ tex texstudio cv build-cv pandoc];

            shellHook = "exec fish";

          };
      });
}

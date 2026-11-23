{
  description = "BookOrbit self-hosted library and reading platform";

  inputs = {
    cloudscraper-enhanced = {
      inputs = {
        flake-lib.follows = "flake-lib";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:jgus-org/cloudscraper-enhanced-flake";
    };
    flake-lib.url = "github:jgus-org/flake-lib/v1";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      cloudscraper-enhanced,
      flake-lib,
      nixpkgs,
      ...
    }:
    let
      kepubifyBinaries = {
        aarch64-darwin = "kepubify-darwin-arm64";
        aarch64-linux = "kepubify-linux-arm64";
        x86_64-linux = "kepubify-linux-64bit";
      };
      pin = import ./pin.nix;
      source = {
        owner = "bookorbit";
        repo = "bookorbit";
        type = "github";
      };
    in
    flake-lib.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ cloudscraper-enhanced.overlays.default ];
        };
        inherit (pkgs) lib;
        orgFormatting = flake-lib.lib.mkFormatting {
          inherit self system;
        };
        src = pkgs.fetchFromGitHub {
          inherit (source) owner repo;
          hash = pin.sourceHash;
          rev = pin.sourceRev;
        };
        python = pkgs.python3.withPackages (ps: [ ps.cloudscraper-enhanced ]);
        bookorbitDeps = flake-lib.lib.mkPnpmDeps {
          inherit pkgs src;
          fetcherVersion = 4;
          hash = pin.pnpmDepsHash;
          nativeBuildInputs = [ pkgs.nodejs ];
          pname = "bookorbit";
          pnpmMajor = pin.pnpmMajor;
          sourceFingerprint = pin.sourceHash;
          version = pin.version;
        };
        bookorbitToolchain = bookorbitDeps.passthru.pnpmToolchain;
      in
      {
        checks.formatting = orgFormatting.check;
        formatter = orgFormatting.formatter;
        packages = rec {
          bookorbit = pkgs.stdenvNoCC.mkDerivation {
            buildPhase = ''
              runHook preBuild

              pnpm --config.verify-deps-before-run=false --filter client run build-only
              pnpm --config.verify-deps-before-run=false --filter server run build
              pnpm --offline --config.allow-unused-patches=true --config.inject-workspace-packages=true --filter server deploy --prod runtime
              rm -rf runtime/dist runtime/migrations runtime/bin runtime/koreader-plugin runtime/public
              cp -r client/dist runtime/public
              cp -r server/dist runtime/dist
              cp -r server/src/db/migrations runtime/migrations
              cp -r server/bin runtime/bin
              mkdir -p runtime/koreader-plugin
              cp -r koreader-plugin/bookorbit.koplugin runtime/koreader-plugin/bookorbit.koplugin

              runHook postBuild
            '';
            doInstallCheck = true;
            installCheckPhase = ''
              runHook preInstallCheck

              test ! -e "''${out}/lib/bookorbit/dist/dist"
              test -f "''${out}/lib/bookorbit/public/index.html"
              test -f "''${out}/lib/bookorbit/migrations/meta/_journal.json"
              test -f "''${out}/lib/bookorbit/koreader-plugin/bookorbit.koplugin/main.lua"
              test -f "''${out}/lib/bookorbit/koreader-plugin/bookorbit.koplugin/_meta.lua"
              test -x "''${out}/lib/bookorbit/bin/kepubify/${kepubifyBinaries.${system}}"
              "''${out}/lib/bookorbit/bin/kepubify/${kepubifyBinaries.${system}}" --version >/dev/null
              PYTHONPATH=${pkgs.writeTextDir "sitecustomize.py" (builtins.readFile ./tests/sitecustomize.py)} \
                KOBO_CLOUDSCRAPER_PYTHON=${lib.getExe python} \
                BOOKORBIT_ROOT="''${out}" \
                ${lib.getExe pkgs.nodejs} ${./tests/kobo-check.mjs}

              runHook postInstallCheck
            '';
            installPhase = ''
              runHook preInstall

              mkdir -p "''${out}/lib/bookorbit" "''${out}/bin"
              cp -r runtime/. "''${out}/lib/bookorbit"
              install -Dm755 server/entrypoint.sh "''${out}/lib/bookorbit/entrypoint.sh"
              makeWrapper ${lib.getExe pkgs.nodejs} "''${out}/bin/bookorbit" \
                --add-flags "''${out}/lib/bookorbit/dist/main.js" \
                --chdir "''${out}/lib/bookorbit" \
                --set BOOKORBIT_ROOT "''${out}/lib/bookorbit" \
                --set KOBO_CLOUDSCRAPER_PYTHON ${lib.getExe python} \
                --set KOREADER_PLUGIN_PATH "''${out}/lib/bookorbit/koreader-plugin/bookorbit.koplugin" \
                --prefix PATH : ${
                  lib.makeBinPath [
                    pkgs.ffmpeg-headless
                    pkgs.poppler-utils
                  ]
                }
              makeWrapper ${lib.getExe pkgs.nodejs} "''${out}/bin/bookorbit-migrate" \
                --add-flags "''${out}/lib/bookorbit/dist/scripts/migrate.js" \
                --chdir "''${out}/lib/bookorbit"

              runHook postInstall
            '';
            meta = {
              description = "Self-hosted library management and reading platform";
              homepage = "https://github.com/bookorbit/bookorbit";
              license = lib.licenses.agpl3Only;
              mainProgram = "bookorbit";
              platforms = builtins.attrNames kepubifyBinaries;
              sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
            };
            nativeBuildInputs = [
              pkgs.makeWrapper
              pkgs.nodejs
              pkgs.pnpmConfigHook
              bookorbitToolchain.pnpm
            ];
            patches = [ ./patches/0001-fix-incremental-opf-scans-and-file-deletions.patch ];
            pname = "bookorbit";
            pnpmDeps = bookorbitDeps;
            src = bookorbitToolchain.src;
            version = pin.version;
          };
          default = bookorbit;
          update-branches = flake-lib.lib.mkUpdateBranches {
            inherit pkgs source;
            extraHashes = [ "pnpmMajor" ];
            minimumTrackingVersion = "3.7.0";
            pinSchema = "github-pnpm";
          };
          update-version = flake-lib.lib.mkUpdateVersion {
            inherit pkgs source;
            artifactHook = flake-lib.lib.mkPnpmDeclarationHook {
              inherit pkgs;
            };
            buildFailureHash = "pnpmDepsHash";
            extraHashes = [ "pnpmMajor" ];
          };
        };
      }
    );
}

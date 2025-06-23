{
  description = "nodejs-version-pinned-flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        pkgsStable = import nixpkgs-stable {
          inherit system;
        };
        nodeVersion = "22.16.0";

        # map Nix system strings (e.g. aarch64-darwin) to Node.js architecture strings (e.g. darwin-arm64)
        nixSystemStringsToNodeArchitectureStrings =
          input:
          builtins.replaceStrings
            [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ]
            [ "linux-x64" "linux-arm64" "darwin-arm64" ]
            input;

        # map Node.js architecture strings (e.g. darwin-arm64) to Nix system strings (e.g. aarch64-darwin)
        nodeArchitectureStringsToNixSystemStrings =
          input:
          builtins.replaceStrings
            [ "linux-x64" "linux-arm64" "darwin-arm64" ]
            [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ]
            input;

        stringHasSuffix = suffix: s: (builtins.match ".*${pkgs.lib.strings.escapeRegex suffix}$" s) != null;
        stringContains =
          needle: haystack: (builtins.match ".*${pkgs.lib.strings.escapeRegex needle}.*" haystack) != null;

        # Find the relevant Node.js hash for the current system
        relevantNodeHash =
          let
            # Fetch the SHASUMS256.txt file for the specified Node.js version, and parse it for the relevant architecture binary hash to use for fetching the prebuilt binary
            hashList = builtins.readFile (
              pkgs.fetchurl {
                url = "https://nodejs.org/download/release/v${nodeVersion}/SHASUMS256.txt";
                sha256 = builtins.convertHash {
                  hashAlgo = "sha256";
                  hash = "e1f5ad5e2a5654721e7b89d84d27f406e582c46ca0b5cde304c5dcdd7bab8b31"; # This is a hash for the SHASSUMS256.txt file, not the binary
                  toHashFormat = "sri";
                };
              }
            );
            lines = nixpkgs.lib.strings.splitString "\n" (hashList);
            gzipsOnly = builtins.filter (stringHasSuffix ".tar.gz") lines;
            withNixSystemStrings = builtins.map (nodeArchitectureStringsToNixSystemStrings) gzipsOnly;
            relevantArchitecture = builtins.elemAt (builtins.filter (stringContains system) withNixSystemStrings) 0;
            relevantHash = builtins.elemAt (builtins.split "  " relevantArchitecture) 0;
          in
          relevantHash;

        nodeBinaryPath = "https://nodejs.org/dist/v${nodeVersion}/node-v${nodeVersion}-${nixSystemStringsToNodeArchitectureStrings system}.tar.gz";

        # Define Node.js from prebuilt binary
        nodejs = pkgs.stdenv.mkDerivation {
          pname = "nodejs";
          version = nodeVersion;

          # Fetch the prebuilt binary
          src = pkgs.fetchurl {
            url = nodeBinaryPath;
            sha256 = builtins.convertHash {
              hashAlgo = "sha256";
              hash = relevantNodeHash;
              toHashFormat = "sri";
            };
          };

          # Install the binary
          installPhase = ''
            mkdir -p $out/bin $out/include $out/lib
            tar -xzf $src --strip-components=1 -C $out
            ln -s $out/bin/node $out/bin/nodejs
          '';

          # Set environment path
          meta = with pkgs.lib; {
            description = "Prebuilt Node.js binary version ${nodeVersion}";
            platforms = [
              "x86_64-linux"
              "aarch64-linux"
              "aarch64-darwin"
            ];
            homepage = "https://nodejs.org/";
          };
        };
      in
      rec {
        flakedPkgs = pkgs;

        # enables use of `nix shell`
        devShell = pkgs.mkShell {
          # add things you want in your shell here
          buildInputs = with pkgs; [
            nodejs
            corepack_22
            awscli2
            jq
            pgcli
            valkey
            duf
          ];
          shellHook = ''
            export PATH="$PATH:${pkgs.corepack_22}/bin"
          '';
        };
      }
    );
}

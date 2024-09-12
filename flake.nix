{
    description = "benchmarking zig http impls";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/release-24.05";
        flake-utils.url = "github:numtide/flake-utils";

        zig.url = "github:mitchellh/zig-overlay";
        zls.url = "github:zigtools/zls/0.13.0";
        
        rust-overlay.url = "github:oxalica/rust-overlay";
    };

    outputs = inputs@{self, nixpkgs, flake-utils, ...}: 
    let
        overlays = [
            (import inputs.rust-overlay)
            (final: prev: rec {
                zigpkgs = inputs.zig.packages.${prev.system};
                zig = zigpkgs."0.13.0";
                zls = inputs.zls.packages.${prev.system}.zls.overrideAttrs (old: {
                    nativeBuildInputs = [ zig ];
                });
            })
        ];

    in flake-utils.lib.eachDefaultSystem (system:
        let pkgs = import nixpkgs {inherit overlays system; };
        in {
        devShells.default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
                # Zig
                zig
                zls
                # JS
                bun
                nodePackages.typescript-language-server
                # Go
                go
                gopls
                # Rust
                rust-bin.stable.latest.default
                rust-analyzer
                # Python
                (python3.withPackages (ps: with ps; [
                    numpy
                    pandas
                    matplotlib
                ]))
                python312Packages.python-lsp-server
                # Benchmarking
                wrk
                oha
                # Misc
                time
                jq
                curl
                lsof
            ];
        };

        devShell = self.devShells.${system}.default;
    });
}

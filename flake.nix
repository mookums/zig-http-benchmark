{
  description = "benchmarking zig http impls";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
    flake-utils.url = "github:numtide/flake-utils";

    iguana.url = "github:mookums/iguana";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    iguana,
    rust-overlay,
    ...
  }: let
    overlays = [
      (import rust-overlay)
    ];
  in
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit overlays system;};
      iguanaLib = iguana.lib.${system};
    in {
      devShells.default = iguanaLib.mkShell {
        zigVersion = "0.13.0";
        withZls = true;

        extraPackages = with pkgs; [
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
          (python3.withPackages (ps:
            with ps; [
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

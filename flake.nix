{
    description = "benchmarking zig http impls";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/release-24.05";
        zig.url = "github:mitchellh/zig-overlay";
        zls.url = "github:zigtools/zls/0.13.0";
    };

    outputs = inputs@{self, nixpkgs, ...}: 
    let
        overlays = [
            (final: prev: rec {
                zigpkgs = inputs.zig.packages.${prev.system};
                zig = zigpkgs."0.13.0";
                zls = inputs.zls.packages.${prev.system}.zls.overrideAttrs (old: {
                    nativeBuildInputs = [ zig ];
                });
            })
        ];

        system = "x86_64-linux";
        pkgs = import nixpkgs { inherit overlays system; };
    in
    {
        devShells.${system}.default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
                # Zig
                zig
                zls
                # Python
                python3
                python312Packages.matplotlib
                # Benchmarking
                linuxPackages_latest.perf
                wrk
                # Misc
                lsof
            ];
        };
    };
}

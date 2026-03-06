{
  description = "Blutoir - Nerves-based smart meter power management system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        beam = pkgs.beam.packagesWith pkgs.beam.interpreters.erlang_28;
        elixir = beam.elixir_1_19;

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            elixir
          ];
        };
      }
    );
}

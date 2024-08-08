{
  description = "PointQuest Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (pkgs.lib) optional optionals;
        erlang_version = "26.2.2";
        elixir_version = "1.16.2";

        # nodePackages installed will use pkgs.nodejs
        # overlyaing node 18 so they are installed with correct node version
        # https://nixos.wiki/wiki/Node.js
        pkgs = import nixpkgs { inherit system; overlays = [ (final: prev: { nodejs = prev.nodejs-18_x; }) ]; };

        beamBuilder = pkgs.beam.packagesWith (pkgs.beam.interpreters.erlang_26.override {
          version = erlang_version;
          sha256 = "sha256-7S+mC4pDcbXyhW2r5y8+VcX9JQXq5iEUJZiFmgVMPZ0=";
        });

        elixir = beamBuilder.elixir.override {
          version = elixir_version;
          sha256 = "sha256-NUYYxf73Fuk3FUoVFKTo6IN9QCTvzz5wNshIf/nitJA=";
        };
      in
      with pkgs;
      {
        devShell = pkgs.mkShell {
          buildInputs = [
            # Node stuff
            nodejs
            nodePackages.typescript-language-server
            nodePackages.prettier
            # Elixir goodies
            elixir
            (lexical.override { elixir = elixir; })
            glibcLocales
            stripe-cli
          ] ++ optional stdenv.isLinux inotify-tools
          ++ optional stdenv.isDarwin terminal-notifier
          ++ optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
            CoreFoundation
            CoreServices
          ]);
        };
      });
}

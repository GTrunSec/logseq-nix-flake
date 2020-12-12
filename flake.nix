{
  description = "Data Science Environment";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/703f052de185c3dd1218165e62b105a68e05e15f";
    logseq = { url = "github:logseq/logseq"; flake = false; };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, logseq }:
    (flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in
          {
            devShell = import ./shell.nix { inherit pkgs logseq;};
          }
      )
    );
}

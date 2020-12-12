{
  description = "Data Science Environment";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/7ff5e241a2b96fff7912b7d793a06b4374bd846c";
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

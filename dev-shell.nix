{ pkgs, logseq }:
with pkgs;
let
  nodeModules = mkYarnPackage rec {
    name = "logseq-node-moduels";
    packageJSON = ./package.json;
    src = logseq;
    yarnLock = ./yarn.lock;
    yarnNix = ./yarn.nix;
  };

  yarnBuild = stdenv.mkDerivation rec {
    name = "logseq-build";
    src = logseq;
    nativeBuildInputs = [ yarn nodejs clojure ];
    configurePhase = ''
    export HOME=$NIX_BUILD_ROOT
    cp -r ${nodeModules}/libexec/logseq .
    chmod -R +rw logseq
    export PATH=$PWD/logseq/node_modules/.bin/:$PATH
    export NODE_PATH=$PWD/logseq/node_modules/:$PWD/logseq/deps/logseq/node_modules:$NODE_PATH
    yarn config --offline set yarn-offline-mirror $NODE_PATH
    '';
    buildPhase = ''
     yarn --offline run gulp:build
    '';
    installPhase = ''
    mkdir -p $out
    cp -r logseq/node_modules $out
    '';
  };
in
mkShell {
  buildInputs = [
    yarn clojure nodejs
  ];
  shellHook = ''
  cp -ruf ${logseq} ./logseq-src
  chmod -R +rw ./logseq-src
  cp -r ${yarnBuild}/node_modules ./logseq-src
  chmod -R +rw ./logseq-src/node_modules
  cd ./logseq-src
  yarn && yarn watch
  '';
}

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
    name = "logseq";
    src = logseq;
    nativeBuildInputs = [ yarn nodejs clojure ];
    configurePhase = ''
    export HOME=$PWD
    cp -r ${nodeModules}/libexec/logseq .
    chmod -R +rw logseq
    export PATH=$PWD/logseq/node_modules/.bin/:$PATH
    export NODE_PATH=$PWD/logseq/node_modules/:$PWD/logseq/deps/logseq/node_modules:$NODE_PATH
    yarn config --offline set yarn-offline-mirror $NODE_PATH
    '';
    buildPhase = ''
     yarn --offline run gulp:build
     # waiting for the clj2nix repairs deps
     #yarn --offline release
    '';
    installPhase = ''
    mkdir -p $out
    mkdir -p $out/{bin,src}
    cp -r * $out/src/.
    cat <<EOF> $out/bin/logseq
    #!/usr/bin/env bash
    export NODE_PATH=$out/src/logseq/node_modules/:$out/src/logseq/deps/logseq/node_modules:$NODE_PATH
    export PATH=$out/src/logseq/node_modules/.bin/:$PATH
    set -e
    exec yarn --cwd $out/src watch "\$@"
    EOF
    chmod a+x $out/bin/logseq
    '';
  };
in
mkShell {
  buildInputs = [
    yarn clojure nodejs
  ];
  shellHook = ''
  echo ${yarnBuild}
  cp -ruf ${logseq} ./logseq-src
  chmod -R +rw ./logseq-src
  cp -r ${yarnBuild}/logseq/node_modules ./logseq-src
  chmod -R +rw ./logseq-src/node_modules
  cd ./logseq-src
  yarn && yarn watch
  '';
}

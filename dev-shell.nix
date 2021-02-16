{ pkgs, logseq }:
with (import (pkgs.fetchFromGitHub {
    owner = "moretea";
    repo = "yarn2nix";
    rev = "9e7279edde2a4e0f5ec04c53f5cd64440a27a1ae";
    sha256 = "0zz2lrwn3y3rb8gzaiwxgz02dvy3s552zc70zvfqc0zh5dhydgn7";
  })
  {inherit pkgs;});
let
  genPackage = pkgs.runCommand "yarn2Nix" {
    buildInputs = [ yarn2nix ];
  } ''
    cp -r ${logseq} logseq
    chmod -R +rw logseq
    cd logseq
    mkdir -p $out/bin
    sed -i 's|fuzzysort#a66f5813825d2415b606cc69129070c4eb612ae2|fuzzysort|' package.json
    sed -i 's|fuzzysort@git+https://github.com/getstation/fuzzysort#a66f5813825d2415b606cc69129070c4eb612ae2|fuzzysort@git+https://github.com/getstation/fuzzysort|' yarn.lock
    cp package.json $out/package.json
    cp yarn.lock $out/yarn.lock
  '';

  nodeModules = mkYarnPackage rec{
    name = "logseq-node-moduels";
    packageJSON = genPackage + "/package.json";
    src = logseq;
    yarnLock = genPackage + "/yarn.lock";
  };

  cljsdeps = import ./deps.nix { inherit pkgs; };
  classp  = cljsdeps.makeClasspaths {};

  yarnBuild = with pkgs; stdenv.mkDerivation rec {
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
    export CLJ_CONFIG=`pwd`
    export CLJ_CACHE=`pwd`/.cpcache
    yarn --offline run gulp:build
     # waiting for the clj2nix repairs deps
     #clojure -M:release app  -d ${classp}
     #yarn --offline release
     #clojure -Scp ${classp} -M:cljs release app publishing
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
pkgs.mkShell {
  buildInputs = with pkgs;[
    yarn clojure nodejs
  ];
  shellHook = ''
  echo ${yarnBuild}
  echo ${nodeModules}
  cp -rufT ${logseq} logseq-src
  chmod -R +rw ./logseq-src
  cp -r ${yarnBuild}/src/logseq/node_modules ./logseq-src
  chmod -R +rw ./logseq-src/node_modules
  cd ./logseq-src
  yarn && yarn watch
  '';
}

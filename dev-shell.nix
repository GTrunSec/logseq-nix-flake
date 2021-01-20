{ pkgs, logseq }:
with pkgs;
let
  genYarnNix = pkgs.runCommand "yarn2Nix" {
    buildInputs = [yarn2nix];
  } ''
    cp -r ${logseq} logseq
    chmod -R +rw logseq
    cd logseq
    yarn2nix > yarn.nix
    cp yarn.nix $out
  '';
  nodeModules = mkYarnPackage rec {
    name = "logseq-node-moduels";
    packageJSON = logseq + "/package.json";
    src = logseq;
    yarnLock = logseq + "/yarn.lock";
    yarnNix = genYarnNix;
  };

  cljsdeps = import ./deps.nix { inherit pkgs; };
  classp  = cljsdeps.makeClasspaths {};

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
mkShell {
  buildInputs = [
    yarn clojure nodejs
  ];
  shellHook = ''
  echo ${yarnBuild}
  echo ${genYarnNix}
  cp -rufT ${logseq} logseq-src
  chmod -R +rw ./logseq-src
  cp -r ${yarnBuild}/src/logseq/node_modules ./logseq-src
  chmod -R +rw ./logseq-src/node_modules
  cd ./logseq-src
  yarn && yarn watch
  '';
}

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
    cp -r ${nodeModules}/libexec/logseq/node_modules/ .
    chmod -R +rw node_modules
    cp -r ${nodeModules}/libexec/logseq/deps/logseq/node_modules/gulp-postcss/ node_modules/
    export PATH=${nodeModules}/libexec/logseq/node_modules/.bin/:$PATH
    yarn config --offline set yarn-offline-mirror node_modules/
    '';
    buildPhase = ''
     yarn --offline run gulp:build
    '';
    installPhase = ''
    mkdir -p $out
    cp -r node_modules $out
    '';
  };
in
mkShell {
  buildInputs = [
    yarn clojure nodejs
  ];
  shellHook = ''
  cp -r ${logseq} ./logseq-src
  chmod -R +rw ./logseq-src
  cp -r ${yarnBuild}/node_modules ./logseq-src
  chmod -R +rw ./logseq-src/node_modules
  cd ./logseq-src
  yarn && yarn watch
  '';
}

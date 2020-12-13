#!/usr/bin/env nix-shell
#!nix-shell -p git -p yarn -p clojure -p nodejs -i bash
set -euo pipefail

cd logseq-src
yarn && yarn upgrade && yarn release && yarn watch

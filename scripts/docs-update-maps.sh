#!/usr/bin/env bash

set -e
set -o pipefail
set -u

function step { >&2 echo -e "\033[1m\033[36m* $@\033[0m"; }
function finish { >&2 echo -en "\033[0m"; }
trap finish EXIT

OUTPUT="/tmp/`uuidgen`"

step "Updating mapbox-gl-native-ios repository…"
git fetch --all
git fetch --tags

VERSION=${1//ios-v/''}

step "Checking out ios-v${VERSION}"

git checkout ios-v${VERSION}

step "Generating new docs for ${VERSION}…"
make idocument OUTPUT=${OUTPUT} JAZZY_CUSTOM_HEAD="<script src='https://docs.mapbox.com/analytics.js'></script>"

step "Moving new docs folder to ./$VERSION"
rm -rf "./$VERSION"
mkdir -p "./$VERSION"
mv -v $OUTPUT/* "./$VERSION"

step "Switching branch to publisher-production"
git checkout origin/publisher-production
step "Committing API docs for $VERSION"
git add "./$VERSION"
git commit -m "$VERSION [ci skip]" 
step "Finished updating documentation"

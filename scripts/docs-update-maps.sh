#!/usr/bin/env bash

set -e
set -o pipefail
set -u

function step { >&2 echo -e "\033[1m\033[36m* $@\033[0m"; }
function finish { >&2 echo -en "\033[0m"; }
trap finish EXIT

OUTPUT="/tmp/`uuidgen`"
RELEASE_BRANCH="master"

step "Updating mapbox-gl-native-ios repository…"
git fetch --depth=1 --prune
git fetch --tags

VERSION=${1}

step "Checking out ios-v${VERSION}"

git checkout ios-v${VERSION}

step "Generating new docs for ${VERSION}…"
make idocument OUTPUT=${OUTPUT} JAZZY_CUSTOM_HEAD="<script src='https://docs.mapbox.com/analytics.js'></script>"

step "Moving new docs folder to ./$VERSION"
rm -rf "./$VERSION"
mkdir -p "./$VERSION"
mv -v $OUTPUT/* "./$VERSION"

# Do we generate docs for pre-releases?
#if [[ $( echo ${VERSION} | awk '/[0-9]-/' ) ]]; then
#    step "Skipping website updates because ${VERSION} is a pre-release"
#    exit 0
#fi

step "Committing API docs for $VERSION"
git add "./$VERSION"
git commit -m "[maps] Add API docs for $VERSION"
step "Finished updating documentation"

#!/usr/bin/env bash

set -euo pipefail

#
# Usage:
#   ./create-api-downloads-pr.sh <project root> <version number> <sdk file names without zip extension>
# for example:
#   ./create-api-downloads-pr.sh mobile-maps 5.10.0-alpha.1 mapbox-ios-sdk-stripped-dynamic mapbox-ios-sdk-dynamic
#

PROJECT_ROOT=$1
VERSION=$2

TMPDIR=`mktemp -d`

git clone git@github.com:mapbox/api-downloads.git ${TMPDIR}
pushd ${TMPDIR}
git checkout -b ${PROJECT_ROOT}-ios/${VERSION}

#
# Add config file
#

cat << EOF > config/${PROJECT_ROOT}/${VERSION}.yaml
api-downloads: v2
packages:
  ios:
EOF

# Add each zip/framework
for SDK_FILE_NAME in "${@:3}"
do
    echo "    - ${SDK_FILE_NAME}" >> config/${PROJECT_ROOT}/${VERSION}.yaml
done

#
# Commit to branch
#
git add -A
git commit -m "Add config for ${PROJECT_ROOT} @ ${VERSION}"

#
# Create PR
#

gh pr create --title "Update config for ${PROJECT_ROOT} @ ${VERSION}" --body "_Auto-generated PR._"
popd
rm -rf ${TMPDIR}

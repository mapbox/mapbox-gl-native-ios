#!/usr/bin/env bash

set -euo pipefail

function step { >&2 echo -e "\033[1m\033[36m* $@\033[0m"; }
function finish { >&2 echo -en "\033[0m"; }
trap finish EXIT

#
# iOS release tag format is `vX.Y.Z`; `X.Y.Z` gets passed in
# In the case of stripped builds, we also append the `-stripped`.
#

# $1 1.2.3-alpha.4
PUBLISH_VERSION="$1"

# $2 `dynamic` | `static` | `stripped-dynamic` etc
PUBLISH_STYLE="$2"

#
# zip
#
cd build/ios/pkg
ZIP_FILENAME="mapbox-ios-sdk-${PUBLISH_STYLE}.zip"
step "Compressing ${ZIP_FILENAME}…"
rm -f ../${ZIP_FILENAME}
zip -yr ../${ZIP_FILENAME} *
cd ..

#
# report file sizes
#
step "Echoing file sizes…"
du -sh ${ZIP_FILENAME}
du -sch pkg/*
du -sch pkg/dynamic/*

#
# upload
#
DRYRUN=""
if [[ ${SKIP_S3-} ]]; then
    DRYRUN="--dryrun"
fi

PROGRESS=""
if [ -n "${CI:-}" ]; then
    PROGRESS="--no-progress"
fi

step "Uploading ${ZIP_FILENAME} to s3… ${DRYRUN}"

if [ ${PUBLISH_STYLE} = "dynamic-with-events" ]; then
    S3_DESTINATION=s3://mapbox-api-downloads-production/v2/mobile-maps/releases/ios/${PUBLISH_VERSION}/${ZIP_FILENAME}
    DOWNLOAD_URL=https://api.mapbox.com/downloads/v2/mobile-maps/releases/ios/${PUBLISH_VERSION}/${ZIP_FILENAME}
else
    S3_DESTINATION=s3://mapbox-api-downloads-production/v2/mobile-maps/releases/ios/${PUBLISH_VERSION}/packages/${ZIP_FILENAME}
    DOWNLOAD_URL=https://api.mapbox.com/downloads/v2/mobile-maps/releases/ios/packages/${PUBLISH_VERSION}/${ZIP_FILENAME}
fi 

step "About to upload binaries to ${S3_DESTINATION}"
aws s3 cp ${ZIP_FILENAME} ${S3_DESTINATION} ${PROGRESS} ${DRYRUN}
step "Download URL will be ${DOWNLOAD_URL}"

# TODO:

##
## upload & update snapshot
##
#if [[ ${PUBLISH_VERSION} =~ "snapshot" ]]; then
#    step "Updating ${PUBLISH_VERSION} to ${PUBLISH_STYLE}…"
#    GENERIC_ZIP_FILENAME="mapbox-ios-sdk-${PUBLISH_VERSION}.zip"
#    aws s3 cp \
#        s3://mapbox/mapbox-gl-native/ios/builds/${ZIP_FILENAME} \
#        s3://mapbox/mapbox-gl-native/ios/builds/${GENERIC_ZIP_FILENAME} --acl public-read ${PROGRESS} ${DRYRUN}
#fi


# TODO: This needs to move, and wait for PR approval.

##
## verify upload integrity
##
#
#step "Validating local and remote checksums…"
#
#if [[ ! ${SKIP_S3-} ]]; then
#    curl --output remote-${ZIP_FILENAME} ${S3_URL}
#    LOCAL_CHECKSUM=$( shasum -a 256 -b ${ZIP_FILENAME} | cut -d ' ' -f 1 )
#    REMOTE_CHECKSUM=$( shasum -a 256 -b remote-${ZIP_FILENAME} | cut -d ' ' -f 1 )
#
#    if [ "${LOCAL_CHECKSUM}" == "${REMOTE_CHECKSUM}" ]; then
#        echo "Checksums match: ${LOCAL_CHECKSUM}"
#    else
#        echo "Checksums did not match: ${LOCAL_CHECKSUM} != ${REMOTE_CHECKSUM}"
#        exit 1
#    fi
#fi

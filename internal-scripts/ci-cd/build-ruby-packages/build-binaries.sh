#!/bin/bash
set -e

SELFDIR=$(dirname "$0")
ROOTDIR=$(cd "$SELFDIR/../../.." && pwd)
# shellcheck source=../../../lib/library.sh
source "$ROOTDIR/lib/library.sh"

require_envvar ENVIRONMENT_NAME
require_envvar VARIANT_NAME
require_envvar RUBY_PACKAGE_VERSION_ID


IMAGE_VERSION=$(read_single_value_file "$ROOTDIR/environments/$ENVIRONMENT_NAME/image_tag")

if [[ "$VARIANT_NAME" = jemalloc ]]; then
    MOUNT_ARGS=(-v "$(pwd)/jemalloc-bin.tar.gz:/input/jemalloc-bin.tar.gz:ro")
else
    MOUNT_ARGS=()
fi

touch ruby-bin.tar.gz

exec docker run --rm --init \
    -v "$ROOTDIR:/system:ro" \
    -v "$(pwd)/ruby-src.tar.gz:/input/ruby-src.tar.gz:ro" \
    -v "$(pwd)/ruby-bin.tar.gz:/output/ruby-bin.tar.gz" \
    -v "$(pwd)/cache:/cache:delegated" \
    "${MOUNT_ARGS[@]}" \
    -e "VARIANT=$VARIANT_NAME" \
    -e "BUILD_CONCURRENCY=2" \
    -e "PACKAGE_VERSION=$RUBY_PACKAGE_VERSION_ID" \
    -e "ENVIRONMENT_NAME=$ENVIRONMENT_NAME" \
    --user "$(id -u):$(id -g)" \
    "fullstaq/ruby-build-env-$ENVIRONMENT_NAME:$IMAGE_VERSION" \
    /system/container-entrypoints/build-ruby

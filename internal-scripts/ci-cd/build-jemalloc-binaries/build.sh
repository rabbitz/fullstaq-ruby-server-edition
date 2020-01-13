#!/bin/bash
set -e

SELFDIR=$(dirname "$0")
# shellcheck source=../../../lib/library.sh
source "$SELFDIR/../../../lib/library.sh"

require_envvar ENVIRONMENT_NAME


IMAGE_VERSION=$(read_single_value_file "environments/$ENVIRONMENT_NAME/image_tag")

mkdir output
touch output/jemalloc-bin.tar.gz

exec docker run --rm --init \
    -v "$(pwd):/system:ro" \
    -v "$(pwd)/cache/jemalloc-src.tar.bz2:/input/jemalloc-src.tar.bz2:ro" \
    -v "$(pwd)/output/jemalloc-bin.tar.gz:/output/jemalloc-bin.tar.gz" \
    -v "$(pwd)/cache:/cache:delegated" \
    -e "ENVIRONMENT_NAME=$ENVIRONMENT_NAME" \
    -e "BUILD_CONCURRENCY=2" \
    --user "$(id -u):$(id -g)" \
    "fullstaq/ruby-build-env-$ENVIRONMENT_NAME:$IMAGE_VERSION" \
    /system/container-entrypoints/build-jemalloc

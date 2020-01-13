#!/bin/bash
set -e

SELFDIR=$(dirname "$0")
# shellcheck source=../../../lib/library.sh
source "$SELFDIR/../../../lib/library.sh"

require_envvar PACKAGE_FORMAT
require_envvar VARIANT_NAME
require_envvar TEST_IMAGE_NAME
require_envvar RBENV_PACKAGE_BASENAME_DEB
require_envvar RBENV_PACKAGE_BASENAME_RPM
require_envvar COMMON_PACKAGE_BASENAME_DEB
require_envvar COMMON_PACKAGE_BASENAME_RPM


UTILITY_IMAGE_VERSION=$(read_single_value_file environments/utility/image_tag)
RUBY_PKG_PATHS=(ruby-pkgs/*)

mkdir repo

if [[ "$PACKAGE_FORMAT" == DEB ]]; then
    RUBY_DEB_PATH="$(pwd)/${RUBY_PKG_PATHS[0]}"
    RBENV_DEB_PATH="$(pwd)/$RBENV_PACKAGE_BASENAME_DEB"
    COMMON_DEB_PATH="$(pwd)/$COMMON_PACKAGE_BASENAME_DEB"

    echo '--- Entering preparation Docker container ---'
    docker run --rm --init \
        -v "$(pwd):/system:ro" \
        -v "$RUBY_DEB_PATH:/input/$(basename "$RUBY_DEB_PATH"):ro" \
        -v "$RBENV_DEB_PATH:/input/$(basename "$RBENV_DEB_PATH"):ro" \
        -v "$COMMON_DEB_PATH:/input/$(basename "$COMMON_DEB_PATH"):ro" \
        -v "$(pwd)/repo:/output" \
        --user "$(id -u):$(id -g)" \
        "fullstaq/ruby-build-env-utility:$UTILITY_IMAGE_VERSION" \
        /system/container-entrypoints/test-debs-prepare

    echo
    echo '--- Entering main Docker container ---'
    exec docker run --rm --init \
        -v "$(pwd):/system:ro" \
        -v "$(pwd)/repo:/input/repo:ro" \
        -e "EXPECTED_VARIANT=$VARIANT_NAME" \
        -e "DEBUG_ON_FAIL=false" \
        --user root \
        --entrypoint /system/container-entrypoints/test-debs \
        "$TEST_IMAGE_NAME"
else
    RUBY_RPM_PATH="$(pwd)/${RUBY_PKG_PATHS[0]}"
    RBENV_RPM_PATH="$(pwd)/$RBENV_PACKAGE_BASENAME_RPM"
    COMMON_RPM_PATH="$(pwd)/$COMMON_PACKAGE_BASENAME_RPM"

    echo '--- Entering preparation Docker container ---'
    docker run --rm --init \
        -v "$(pwd):/system:ro" \
        -v "$RUBY_RPM_PATH:/input/$(basename "$RUBY_RPM_PATH"):ro" \
        -v "$RBENV_RPM_PATH:/input/$(basename "$RBENV_RPM_PATH"):ro" \
        -v "$COMMON_RPM_PATH:/input/$(basename "$COMMON_RPM_PATH"):ro" \
        -v "$(pwd)/repo:/output" \
        --user "$(id -u):$(id -g)" \
        "fullstaq/ruby-build-env-utility:$UTILITY_IMAGE_VERSION" \
        /system/container-entrypoints/test-rpms-prepare

    echo
    echo '--- Entering main Docker container ---'
    exec docker run --rm --init \
        -v "$(pwd):/system:ro" \
        -v "$(pwd)/repo:/input/repo:ro" \
        -e "EXPECTED_VARIANT=$VARIANT_NAME" \
        -e "DEBUG_ON_FAIL=false" \
        --user root \
        --entrypoint /system/container-entrypoints/test-rpms \
        "$TEST_IMAGE_NAME"
fi

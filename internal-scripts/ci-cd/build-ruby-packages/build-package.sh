#!/bin/bash
set -e

SELFDIR=$(dirname "$0")
# shellcheck source=../../../lib/library.sh
source "$SELFDIR/../../../lib/library.sh"

require_envvar DISTRIBUTION_NAME
require_envvar VARIANT_NAME
require_envvar VARIANT_PACKAGE_SUFFIX
require_envvar PACKAGE_FORMAT
require_envvar RUBY_PACKAGE_VERSION_ID
require_envvar RUBY_PACKAGE_REVISION


IMAGE_VERSION=$(read_single_value_file "environments/utility/image_tag")

mkdir output

if [[ "$PACKAGE_FORMAT" = DEB ]]; then
    PACKAGE_BASENAME=fullstaq-ruby-${RUBY_PACKAGE_VERSION_ID}${VARIANT_PACKAGE_SUFFIX}_${RUBY_PACKAGE_REVISION}-${DISTRIBUTION_NAME}_amd64.deb
    touch "output/$PACKAGE_BASENAME"

    exec docker run --rm --init \
        -v "$(pwd):/system:ro" \
        -v "$(pwd)/ruby-bin.tar.gz:/input/ruby-bin.tar.gz:ro" \
        -v "$(pwd)/output/$PACKAGE_BASENAME:/output/ruby.deb" \
        -e "REVISION=$RUBY_PACKAGE_REVISION" \
        --user "$(id -u):$(id -g)" \
        "fullstaq/ruby-build-env-utility:$IMAGE_VERSION" \
        /system/container-entrypoints/build-ruby-deb
else
    DISTRO_SUFFIX=$(sed 's/-//g' <<<"$DISTRIBUTION_NAME")
    PACKAGE_BASENAME=fullstaq-ruby-${RUBY_PACKAGE_VERSION_ID}${VARIANT_PACKAGE_SUFFIX}-rev${RUBY_PACKAGE_REVISION}-${DISTRO_SUFFIX}.x86_64.rpm
    touch "output/$PACKAGE_BASENAME"

    exec docker run --rm --init \
        -v "$(pwd):/system:ro" \
        -v "$(pwd)/ruby-bin.tar.gz:/input/ruby-bin.tar.gz:ro" \
        -v "$(pwd)/output/$PACKAGE_BASENAME:/output/ruby.rpm" \
        -e "REVISION=$RUBY_PACKAGE_REVISION" \
        --user "$(id -u):$(id -g)" \
        "fullstaq/ruby-build-env-utility:$IMAGE_VERSION" \
        /system/container-entrypoints/build-ruby-rpm
fi

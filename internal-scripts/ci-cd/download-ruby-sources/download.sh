#!/bin/bash
set -e

SELFDIR=$(dirname "$0")
# shellcheck source=../../../lib/library.sh
source "$SELFDIR/../../../lib/library.sh"

require_envvar RUBY_VERSION


MINOR_VERSION=$(sed -E 's/(.+)\..*/\1/' <<<"$RUBY_VERSION")

run wget --output-document ruby-src.tar.gz \
    "https://cache.ruby-lang.org/pub/ruby/$MINOR_VERSION/ruby-$RUBY_VERSION.tar.gz"

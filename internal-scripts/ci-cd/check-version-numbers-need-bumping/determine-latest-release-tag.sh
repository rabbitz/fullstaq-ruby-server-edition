#!/bin/bash
set -e

SELFDIR=$(dirname "$0")
# shellcheck source=../../../lib/library.sh
source "$SELFDIR/../../../lib/library.sh"


run git fetch

echo "+ Calculating..."

MERGE_BASE=$(git merge-base origin/master HEAD)
LATEST_RELEASE_TAG=$(git describe "$MERGE_BASE" --tags --abbrev=0 --match='epic-*')

echo "::set-env name=LATEST_RELEASE_TAG::$LATEST_RELEASE_TAG"
echo "Latest release tag: $LATEST_RELEASE_TAG"

#!/bin/bash
# Checks whether the Rbenv package revision needs bumping.
set -e
set -o pipefail

SELFDIR=$(dirname "$0")
# shellcheck source=../../../lib/library.sh
source "$SELFDIR/../../../lib/library.sh"

require_envvar LATEST_RELEASE_TAG

# The following optional variables are for testing purposes.
HEAD_SHA=${HEAD_SHA:-$(git rev-parse HEAD)}
RBENV_PATH=${RBENV_PATH:-./rbenv}
MOCK_APPROVAL_STATUS=${MOCK_APPROVAL_STATUS:-not set} # may be set to true or false


CURRENT_RBENV_REF=$(ruby -ryaml -e 'puts YAML.load_file("config.yml")["rbenv"]["ref"]')
LATEST_RELEASE_RBENV_REF=$(git archive "$LATEST_RELEASE_TAG" config.yml | tar -xO | ruby -ryaml -e 'puts YAML.load(STDIN)["rbenv"]["ref"]')
HEAD_SHA_SHORT=${HEAD_SHA:0:8}

if [[ "$CURRENT_RBENV_REF" = "$LATEST_RELEASE_RBENV_REF" ]]; then
    REVIEW_GLOB="container-entrypoints/build-rbenv-{deb,rpm}"
    # shellcheck disable=SC2207,SC2012
    REVIEW_FILES=($(ls container-entrypoints/build-rbenv-{deb,rpm} | sort))

    DIFF=$(git diff "$LATEST_RELEASE_TAG"..HEAD "${REVIEW_FILES[@]}")
    if [[ -z "$DIFF" ]]; then
        echo "No change needed: neither the Rbenv version nor relevant scripts changed since the last Fullstaq Ruby release."
    else
        echo "Detected a change in $REVIEW_GLOB."
        echo "Checking whether manual approval is given..."

        APPROVAL_DATA=$(
            echo "project=fullstaq-ruby-server-edition" &&
            echo "base=$LATEST_RELEASE_TAG" &&
            sha256sum "${REVIEW_FILES[@]}"
        )
        APPROVAL_CHECKSUM=$(md5sum <<<"$APPROVAL_DATA" | awk '{ print $1 }')

        if [[ "$MOCK_APPROVAL_STATUS" = true ]]; then
            echo "$APPROVAL_CHECKSUM" > approvals.txt
        elif [[ "$MOCK_APPROVAL_STATUS" = false ]]; then
            echo -n > approvals.txt
        else
            curl -fsSLO https://raw.githubusercontent.com/fullstaq-labs/fullstaq-ruby-ci-approvals/master/approvals.txt
        fi

        if grep -q "^${APPROVAL_CHECKSUM}$" approvals.txt; then
            echo "Manual approval detected."
        else
            echo "No manual approval detected."
            echo
            echo "${BOLD}${YELLOW}*** MANUAL REVIEW AND ACTION REQUIRED ***${RESET}"
            echo
            echo "$REVIEW_GLOB has changed. ${BOLD}Please review${RESET} the changes"
            echo "in these files between $LATEST_RELEASE_TAG and $HEAD_SHA_SHORT:"
            echo
            echo "  ${CYAN}git diff $LATEST_RELEASE_TAG..$HEAD_SHA_SHORT $REVIEW_GLOB${RESET}"
            echo
            echo "${BOLD}${YELLOW}## How to review?${RESET}"
            echo
            echo "Check whether the code would ${BOLD}change the Rbenv package contents or metadata${RESET}."
            echo
            echo "${BOLD}${YELLOW}## How to take action?${RESET}"
            echo
            echo " * If the Rbenv package contents or metadata will change then, then edit"
            echo "   config.yml and bump rbenv.package_revision."
            echo
            echo "  ${BOLD}-- OR --${RESET}"
            echo
            echo " * If not, approve this change by adding this line..."
            echo
            echo "     $APPROVAL_CHECKSUM"
            echo
            echo "   ...to github.com/fullstaq-labs/fullstaq-ruby-ci-approvals,"
            echo "   file approvals.txt:"
            echo
            echo "     https://github.com/fullstaq-labs/fullstaq-ruby-ci-approvals/edit/master/approvals.txt"
            echo
            echo "   You can also use this command:"
            echo
            echo "     git clone --depth=1 git@github.com:fullstaq-labs/fullstaq-ruby-ci-approvals.git &&"
            echo "     cd fullstaq-ruby-ci-approvals &&"
            echo "     echo $APPROVAL_CHECKSUM >> approvals.txt &&"
            echo "     git commit -a -m 'Approve fullstaq-ruby-server-edition $HEAD_SHA_SHORT' &&"
            echo "     git push"
        fi
    fi
else
    echo " * The Rbenv Git ref has changed compared to $LATEST_RELEASE_TAG."
    echo
    echo "       Was: $LATEST_RELEASE_RBENV_REF"
    echo "    Is now: $CURRENT_RBENV_REF"
    echo

    CURRENT_RBENV_VERSION=$("$RBENV_PATH"/bin/rbenv --version | awk '{ print $2 }' | sed -E 's/(.+)-.*/\1/')
    CURRENT_RBENV_PACKAGE_REVISION=$(ruby -ryaml -e 'puts YAML.load_file("config.yml")["rbenv"]["package_revision"]')
    LATEST_RELEASE_RBENV_VERSION=$(ruby -ryaml -e 'puts YAML.load_file("config.yml")["rbenv"]["version"]')
    LATEST_RELEASE_RBENV_PACKAGE_REVISION=$(git archive "$LATEST_RELEASE_TAG" config.yml | tar -xO | ruby -ryaml -e 'puts YAML.load(STDIN)["rbenv"]["package_revision"]')

    if [[ "$CURRENT_RBENV_VERSION" = "$LATEST_RELEASE_RBENV_VERSION" ]]; then
        echo " * The Rbenv version stayed the same compared to $LATEST_RELEASE_TAG."
        echo

        if [[ "$CURRENT_RBENV_PACKAGE_REVISION" -gt "$LATEST_RELEASE_RBENV_PACKAGE_REVISION" ]]; then
            echo " * No change needed: package revision has been bumped."
        else
            echo "${BOLD}${YELLOW}*** ACTION REQUIRED ***${RESET}"
            echo "Please edit config.yml and bump ${BOLD}rbenv.package_revision${RESET}"
            exit 1
        fi
    else
        echo " * The Rbenv version has changed compared to $LATEST_RELEASE_TAG."
        echo
        echo "       Was: $LATEST_RELEASE_RBENV_VERSION"
        echo "    Is now: $CURRENT_RBENV_VERSION"
        echo

        if [[ "$CURRENT_RBENV_PACKAGE_REVISION" = 0 ]]; then
            echo "* No change needed: package revision has been reset to 0."
        else
            echo "${BOLD}${YELLOW}*** ACTION REQUIRED ***${RESET}"
            echo "Please edit config.yml and change ${BOLD}rbenv.package_revision${RESET} to 0"
            exit 1
        fi
    fi
fi

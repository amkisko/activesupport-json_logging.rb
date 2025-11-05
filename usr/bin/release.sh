#!/bin/bash

set -e

e() {
    GREEN='\033[0;32m'
    NC='\033[0m'
    RED='\033[1;31m'
    echo -e "${GREEN}$1${NC}"
    if ! eval "$1"; then
        echo -e "${RED}Command failed: $1${NC}" >&2
        exit 1
    fi
}

e "bundle"
e "bundle exec appraisal install"
e "bundle exec standardrb --fix"
e "bundle exec rbs validate"
e "bundle exec rspec"

echo "Tests passed. Checking git status..."

if [[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]]; then
  echo -e "\033[1;31mgit working directory not clean, please commit your changes first \033[0m"
  echo -e "\033[1;33mNote: standardrb --fix may have modified files. Review and commit changes before releasing.\033[0m"
  exit 1
fi

GEM_NAME="activesupport-json_logging"
VERSION=$(grep -Eo "VERSION\s*=\s*\".+\"" lib/json_logging/version.rb  | grep -Eo "[0-9.]{5,}")
GEM_FILE="$GEM_NAME-$VERSION.gem"

e "gem build $GEM_NAME.gemspec"

echo "Ready to release $GEM_FILE $VERSION"
read -p "Continue? [Y/n] " answer
if [[ "$answer" != "Y" ]]; then
  echo "Exiting"
  exit 1
fi

e "gem push $GEM_FILE"
e "git tag $VERSION && git push --tags"
e "gh release create $VERSION --generate-notes"


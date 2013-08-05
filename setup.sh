#!/bin/bash

# This cannot be executed from within a Ruby-based environment (like Rake)
# since Bundler will affect the subshell environments.

set -e

function header() {
  echo -e "\n$1:\n======================================="
}

if [[ $1 == "install" ]]; then
  header "Installing gem dependencies"
  bundle install --quiet && echo "OK"

  for app in spec/railsapps/*; do
    (
      cd $app
      header "Installing gems for $app"
      bundle install --quiet && echo "OK"
    )
  done
  echo ""

elif [[ $1 == "update" ]]; then
  header "Updating gem dependencies"
  bundle update

  for app in spec/railsapps/*; do
    (
      cd $app
      header "Updating $app"
      bundle update
    )
  done
  echo ""

else
  echo "Usage: $0 [install|update]"
  echo ""
  echo "  Install: Install all bundled updates."
  echo "  Update: Run bundle update on all bundles."
  echo ""
  exit 127
fi

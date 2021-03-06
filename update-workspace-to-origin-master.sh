#!/bin/bash
set -eu

echo "Creating workspace..."
./create-workspace.sh
echo "Resetting workspace..."
./reset-workspace.sh
echo "Fetch origin..."
./with-all-repos-in-workspace.sh git fetch origin
echo "Check out origin/master as a new branch..."
./with-all-repos-in-workspace.sh git checkout origin/master -B tmpbranch --no-track

#!/bin/bash
set -e

# Specify the base URL
BASE_URL=${1:-"http://localhost:1313"}

echo "Using base URL: $BASE_URL"

# Version configuration - modify these arrays to specify versions to build
# Format: "ref:display_name" (ref can be tag, branch, or commit hash, display name is what will appear in URL)
MAIN_VERSION="v0.10.1:latest"
VERSIONS=(
  "main:latest" # latest version always builds from main
  "v0.9.6:v0.9"
  "v0.8.6:v0.8"
)

# Parse main version
IFS=':' read -r MAIN_REF MAIN_NAME <<< "$MAIN_VERSION"

# Ensure clean public directory
rm -rf public
mkdir -p public
mkdir -p public/versions

# Checkout and build main site
if git rev-parse --verify "$MAIN_REF" >/dev/null 2>&1; then
  git checkout $MAIN_REF
  GIT_HASH=$(git rev-parse --short HEAD)
  echo "Building main site from $MAIN_REF (commit: $GIT_HASH)"
else
  echo "Warning: $MAIN_REF not found, using current branch"
  GIT_HASH=$(git rev-parse --short HEAD)
  echo "Building main site from current branch (commit: $GIT_HASH)"
fi
hugo \
  --minify \
  --themesDir=../.. --source=exampleSite \
  --baseURL "$BASE_URL/" \
  --destination=../public

# Build all versions
for VERSION in "${VERSIONS[@]}"; do
  IFS=':' read -r REF NAME <<< "$VERSION"

  if git rev-parse --verify "$REF" >/dev/null 2>&1; then
    git checkout $REF
    GIT_HASH=$(git rev-parse --short HEAD)
    echo "Building version $NAME from $REF (commit: $GIT_HASH)"

    mkdir -p "public/versions/$NAME"
    hugo \
      --minify \
      --themesDir=../.. --source=exampleSite \
      --baseURL "$BASE_URL/versions/$NAME/" \
      --destination="../public/versions/$NAME"
  else
    echo "Warning: $REF not found, skipping version $NAME"
  fi
done

# Return to main branch
git checkout main

echo "Build completed"

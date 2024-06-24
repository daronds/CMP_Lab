#!/bin/bash

# Initialize variables
ALL=false
PRESIGNED=false

# Usage Instructions
usage() {
  echo "Usage: $0 [--all] [--presigned] [--type TYPE] [--number NUMBER] [--version VERSION]"
  echo "  --all       Return all matching links instead of the latest one"
  echo "  --presigned Return a presigned URL instead of an S3 link"
  echo "  --type      The type of the build (PR/rc/ga)"
  echo "  --number    The number associated with the build type"
  echo "  --version   The version of cmp ie 2023.4.1 (only for GA)"
  exit 1
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --all) ALL=true ;;
    --presigned) PRESIGNED=true ;;
    --type) shift; TYPE=$(echo $1 | tr '[:lower:]' '[:upper:]') ;;
    --number) shift; NUMBER=$1 ;;
    --version) shift; VERSION=$1 ;;
    --help) usage ;;
    *) echo "Unknown parameter passed: $1"; usage ;;
  esac
  shift
done

# Check if type is provided
if [ -z "$TYPE" ]; then
  read -p "Enter the type (PR/rc/ga): " TYPE
  TYPE=$(echo $TYPE | tr '[:lower:]' '[:upper:]')
  if [ -z "$TYPE" ] || { [ "$TYPE" != "PR" ] && [ "$TYPE" != "RC" ] && [ "$TYPE" != "GA" ]; }; then
    echo "Error: Invalid type. Please enter PR, rc, or ga."
    exit 1
  fi
fi

# Check if number is provided for non-GA types
if [[ "$TYPE" != "GA" && -z "$NUMBER" ]]; then
  read -p "Please enter a $TYPE number: " NUMBER
  if [ -z "$NUMBER" ]; then
    echo "Error: $TYPE number is required."
    exit 1
  fi
fi

# Check if version is provided for GA types
if [[ "$TYPE" == "GA" && -z "$VERSION" ]]; then
  read -p "Please enter a $TYPE version: " VERSION
  if [ -z "$VERSION" ]; then
    echo "Error: $TYPE version is required."
    exit 1
  fi
fi

# Construct search string and version filter based on type
if [ "$TYPE" == "RC" ]; then
  SEARCH_STRING="$(echo $TYPE. | tr '[:upper:]' '[:lower:]')$NUMBER"
  VERSION_FILTER="grep -E '20[0-9]{2}\.[0-9]+\.[0-9]+'"
elif [ "$TYPE" == "GA" ]; then
  SEARCH_STRING="$VERSION"
  VERSION_FILTER="grep -Ev '(PR|rc)'"
else
  SEARCH_STRING="$TYPE$NUMBER"
  VERSION_FILTER="cat"
fi

# Fetch links from S3 and construct URLs
if $ALL; then
  LINKS=$(aws s3 ls --recursive cb-internal-builds | grep "$SEARCH_STRING" | eval $VERSION_FILTER | grep -v "sum" | sort --version-sort | awk '{print $4}')
else
  LINK=$(aws s3 ls --recursive cb-internal-builds | grep "upgrader" | grep -v "latest" | grep -v "develop" | grep "$SEARCH_STRING" | eval $VERSION_FILTER | grep -v "sum" | sort --version-sort | tail -n 1 | awk '{print $4}')
fi

# Check if valid links are found
if [ -z "$LINK" ] && [ -z "$LINKS" ]; then
  echo "No upgrader links found for $SEARCH_STRING"
  exit 1
fi

# ...

# Make the link expire in 1 week instead of the short default of 1 hour for when the PRAs fail,
# and need to be fixed and re-run, sometimes repeatedly.
URL=$(aws s3 presign "s3://cb-internal-builds/$LINK" --expires-in 604800)
echo "$URL"

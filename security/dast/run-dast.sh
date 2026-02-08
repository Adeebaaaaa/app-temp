#!/bin/bash
set -e

TARGET_URL="$1"

if [ -z "$TARGET_URL" ]; then
  echo "ERROR: No URL provided to DAST scan"
  exit 1
fi

# Remove trailing slash if present
TARGET_URL="${TARGET_URL%/}"

echo "Running basic DAST checks on $TARGET_URL"

STATUS_CODE=$(curl -o /dev/null -s -w "%{http_code}" "$TARGET_URL")

if [ "$STATUS_CODE" -ne 200 ]; then
  echo "ERROR: App did not return HTTP 200 (got $STATUS_CODE)"
  exit 1
fi

echo "DAST checks passed (basic)"

#!/bin/bash
set -e

echo "Starting E2E tests..."

if [ -z "$BASE_URL" ]; then
  echo "ERROR: BASE_URL is not set"
  exit 1
fi

echo "Testing root endpoint..."
RESPONSE=$(curl -s "$BASE_URL/")

if [[ "$RESPONSE" != *"Hello World"* ]]; then
  echo "ERROR: Unexpected response from app"
  echo "Response was: $RESPONSE"
  exit 1
fi

echo "E2E tests passed successfully"

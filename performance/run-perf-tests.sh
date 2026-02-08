#!/bin/bash
set -e

echo "Running performance tests..."

if [ -z "$BASE_URL" ]; then
  echo "ERROR: BASE_URL is not set"
  exit 1
fi

TIME_TOTAL=$(curl -o /dev/null -s -w "%{time_total}" "$BASE_URL/")

echo "Response time: ${TIME_TOTAL}s"

MAX_TIME=2.0

if (( $(echo "$TIME_TOTAL > $MAX_TIME" | bc -l) )); then
  echo "ERROR: Response time exceeded ${MAX_TIME}s"
  exit 1
fi

echo "Performance tests passed"

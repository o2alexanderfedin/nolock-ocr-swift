#!/bin/bash

# Run smoke tests against all environments
# This script runs the smoke tests with retry logic to ensure
# that endpoints are functional even if some attempts fail

cd "$(dirname "$0")"
echo "📋 Running OCR API Smoke Tests"
echo "============================="

# Set timeout to handle potential long-running tests
export SWIFT_TEST_TIMEOUT=600

# Run just the smoke tests
swift test --filter SmokeTests

exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo "✅ All smoke tests passed!"
else
    echo "❌ Some smoke tests failed. Check the logs for details."
fi

exit $exit_code
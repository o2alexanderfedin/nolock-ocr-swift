#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Path to the mockingbird CLI
MOCKINGBIRD_CLI=".build/checkouts/mockingbird/mockingbird"

# Check if Swift Package Manager has already downloaded mockingbird
if [ ! -f "$MOCKINGBIRD_CLI" ]; then
    echo "Mockingbird CLI not found, building dependencies..."
    swift package resolve
fi

# Check again after resolving dependencies
if [ ! -f "$MOCKINGBIRD_CLI" ]; then
    echo "Error: Could not find mockingbird CLI after resolving dependencies."
    echo "Try running 'swift package update' first."
    exit 1
fi

# Ensure the output directory exists
mkdir -p Tests/Mocks/Generated

echo "Generating mocks..."
$MOCKINGBIRD_CLI generate --targets "NolockOCR" --output "Tests/Mocks/Generated"

echo "Mocks generated successfully."
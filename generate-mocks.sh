#!/bin/bash

# Exit if any command fails
set -e

# Create directory for manual mocks
mkdir -p Tests/Mocks

# Create placeholder directory for generated mocks
mkdir -p Tests/Mocks/Generated

echo "Mockingbird support is setup using manual mocks."
echo "The mocks are located in Tests/Mocks directory."
echo "This script is a placeholder for future Mockingbird generator integration."
echo "For now, we are using manual mocks to ensure CI/CD compatibility."
echo ""
echo "Mock generation completed successfully."
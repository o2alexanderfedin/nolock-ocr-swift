#!/bin/bash

# Generate XCode project
swift package generate-xcodeproj

# Install Mockingbird CLI if not already installed
if ! command -v mockingbird &> /dev/null; then
    echo "Installing Mockingbird CLI..."
    brew install mockingbird
fi

# Generate mocks
mockingbird generate
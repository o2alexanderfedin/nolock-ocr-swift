#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure the output directory exists
mkdir -p Tests/Mocks/Generated

# Download Mockingbird if needed
MOCKINGBIRD_DIR="bin/mockingbird"
MOCKINGBIRD_VERSION="0.20.0"
MOCKINGBIRD_BIN="$MOCKINGBIRD_DIR/Mockingbird/mockingbird"

if [ ! -f "$MOCKINGBIRD_BIN" ]; then
    echo "Downloading Mockingbird..."
    mkdir -p "$MOCKINGBIRD_DIR"
    curl -L "https://github.com/birdrides/mockingbird/releases/download/$MOCKINGBIRD_VERSION/Mockingbird.zip" -o "$MOCKINGBIRD_DIR/Mockingbird.zip"
    unzip -o "$MOCKINGBIRD_DIR/Mockingbird.zip" -d "$MOCKINGBIRD_DIR"
    chmod +x "$MOCKINGBIRD_BIN"
fi

# Create a project.json file for Mockingbird
PROJECT_JSON="$MOCKINGBIRD_DIR/project.json"
cat > "$PROJECT_JSON" << EOF
{
  "targets": [
    {
      "name": "NolockOCR",
      "type": "framework",
      "sources": ["Sources"]
    }
  ]
}
EOF

echo "Generating mocks..."
"$MOCKINGBIRD_BIN" generate --project "$PROJECT_JSON" --targets "NolockOCR" --output "Tests/Mocks/Generated" --srcroot "$(pwd)"

echo "Mocks generated successfully."
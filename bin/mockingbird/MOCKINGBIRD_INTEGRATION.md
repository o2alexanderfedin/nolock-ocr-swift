# Mockingbird Integration Guide

This document provides instructions for setting up Mockingbird in this project.

## Manual Integration

Due to challenges with direct SPM integration of Mockingbird, we're using a hybrid approach with manual mocks. This approach uses:

1. Manual mock implementations in `Tests/Mocks/` directory
2. The ability to download Mockingbird binary for code generation in the future

## Setup Process

### 1. Download Mockingbird Binary

```bash
# Create mockingbird directory
mkdir -p bin/mockingbird

# Download latest release
curl -L "https://github.com/birdrides/mockingbird/releases/download/0.20.0/Mockingbird.zip" -o "bin/mockingbird/Mockingbird.zip"

# Extract the archive
unzip "bin/mockingbird/Mockingbird.zip" -d "bin/mockingbird"

# Make the binary executable
chmod +x "bin/mockingbird/Mockingbird/mockingbird"
```

### 2. Generate Project Configuration

Create a `project.json` file for Mockingbird:

```json
{
  "targets": [
    {
      "name": "NolockOCR",
      "type": "framework",
      "sources": ["Sources"]
    }
  ]
}
```

### 3. Generate Mocks

Run the Mockingbird binary to generate mocks:

```bash
./bin/mockingbird/Mockingbird/mockingbird generate \
  --project "bin/mockingbird/project.json" \
  --targets "NolockOCR" \
  --output "Tests/Mocks/Generated" \
  --srcroot "$(pwd)"
```

## Using the Manual Mocks

Until the Mockingbird generation is fully working, we've created manual mock implementations:

1. `MockURLSession` in `Tests/Mocks/MockURLSession.swift` - A manual mock for URLSessionProtocol
2. `MockProcessingIO` in `Tests/Mocks/MockProcessingIO.swift` - A manual mock for OCRProcessingIO
3. `MockOCRItem` in `Tests/Mocks/MockProcessingIO.swift` - A manual mock for OCRProcessable

These mocks provide the same functionality as Mockingbird-generated mocks but without the dependency on the Mockingbird runtime.

## CI/CD Integration

In the CI/CD pipeline, we include the following steps:

1. Download and extract Mockingbird
2. Set up the project configuration
3. Attempt to generate mocks (if this fails, we fall back to the manual mocks)
4. Run the tests

This approach ensures our tests can run in any environment, even if Mockingbird mock generation fails.

## Future Improvements

When moving to a more stable Mockingbird integration:

1. Create dedicated mock generation scripts
2. Use the Mockingbird protocol-only generation feature 
3. Implement better error handling in CI/CD for mock generation failures
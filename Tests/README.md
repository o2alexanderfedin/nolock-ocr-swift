# Swift Proxy Integration Tests

> Copyright © 2025 [Nolock.social](https://nolock.social). All rights reserved.  
> Authored by: [O2.services](https://o2.services)  
> Contact: [sales@o2.services](mailto:sales@o2.services)  
> Licensed under the [GNU Affero General Public License v3.0 or later](https://www.gnu.org/licenses/agpl-3.0.html) (AGPL-3.0-or-later)

This directory contains tests for the Swift proxy client for the OCR Checks Server.

## Test Types

1. **Unit Tests** (`OCRClientAsyncTests.swift`): Tests the Swift proxy client with mocked responses. These tests can run independently without a server.

2. **Integration Tests** (`OCRClientIntegrationTests.swift`): End-to-end tests that communicate with a running server instance. These tests verify that the Swift proxy can correctly interact with the actual server.

## Running Unit Tests

Unit tests can be run standalone without additional setup:

```bash
cd swift-proxy
swift test
```

## Running Integration Tests

Integration tests require a running server instance:

1. Start the server in one terminal:
   ```bash
   npm run dev
   ```

2. Run the Swift tests in another terminal:
   ```bash
   cd swift-proxy
   swift test
   ```

### Integration Test Configuration

By default, integration tests will try to connect to a local server running at `http://localhost:8787`. If the server is not available, the tests will be automatically skipped rather than failing.

You can also explicitly skip integration tests by setting an environment variable:

```bash
OCR_SKIP_INTEGRATION_TESTS=1 swift test
```

#### Testing Against Remote Server

The Swift integration tests can be configured to run against a remote server by setting the `OCR_API_URL` environment variable:

```bash
export OCR_API_URL="https://ocr-checks-worker.af-4a0.workers.dev"
cd swift-proxy
swift test
```

This will direct all tests to use the specified remote server instead of a local instance.

## Test Images

Integration tests use check/receipt images from the `tests/fixtures/images` directory. The tests look for various test images like `rental-bill.jpg`, `fredmeyer-receipt.jpg`, and `promo-check.HEIC` in several common locations relative to the test runner.

## Troubleshooting

If integration tests are failing:

1. Ensure the server is running at http://localhost:8787 (or the URL specified in OCR_API_URL)
2. Verify the test images exist in `tests/fixtures/images/` directory
3. Check server logs for any errors
4. Try running with increased timeout if network latency is an issue
5. If you encounter errors about image format or base64 encoding, verify that OCRClient is formatting requests correctly for the server's API expectations:
   - JPEG images should use "Content-Type: image/jpeg"
   - PNG images should use "Content-Type: image/png"
   - HEIC images are automatically converted to PNG and use "Content-Type: image/png"
6. When running against the production API, ensure you have a valid API key configured
7. Look for error messages in the test output - they often contain detailed information about what went wrong

## Adding New Tests

When adding new tests:

1. **Unit Tests**: Add to `OCRClientAsyncTests.swift` with appropriate mocks
2. **Integration Tests**: Add to `OCRClientIntegrationTests.swift` with appropriate timeout handling

Both test types are important for ensuring the Swift proxy works correctly:
- Unit tests provide fast feedback and test edge cases
- Integration tests verify end-to-end functionality with the actual server
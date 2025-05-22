# Test Mocks

This directory contains manual mock implementations for testing the NolockOCR Swift package.

## Manual Mocks

The following manual mock implementations are provided:

- `MockURLSession.swift` - A mock implementation of `URLSessionProtocol` for testing network interactions
- `MockProcessingIO.swift` - A mock implementation of `OCRProcessingIO` for testing the processing service
- `MockOCRItem` - A mock implementation of `OCRProcessable` for testing with document items

## Usage in Tests

These mocks can be used directly in tests:

```swift
import XCTest
@testable import NolockOCR

class MyTests: XCTestCase {
    var mockSession: MockURLSession!
    var mockIO: MockProcessingIO!
    
    override func setUp() {
        mockSession = MockURLSession()
        mockIO = MockProcessingIO()
        
        // Configure mocks as needed
        mockSession.mockResponse = HTTPURLResponse(...)
        mockSession.mockData = yourTestData
        
        // Use mocks in your service
        OCRClient.useCustomURLSession(mockSession)
        yourService = ServiceUnderTest(io: mockIO)
    }
    
    func testExample() {
        // Your test code here
    }
}
```

## Mockingbird Integration

This project also supports [Mockingbird](https://github.com/birdrides/mockingbird) for more advanced mocking scenarios. However, the manual mocks are the preferred approach for most testing needs because:

1. They're simpler to use and understand
2. They don't require additional dependencies
3. They work reliably in all environments including CI/CD

If you need to use Mockingbird, see the integration guide in `bin/mockingbird/MOCKINGBIRD_INTEGRATION.md`.

## Generated Mocks

The `Generated/` subdirectory is used for Mockingbird-generated mocks. These files are not committed to the repository and will be generated on demand by the `generate-mocks.sh` script.

To generate mocks:

```bash
./generate-mocks.sh
```

## Contributing New Mocks

When adding new mock implementations:

1. Follow the existing pattern of manual mocks
2. Provide clear documentation for your mock's behavior
3. Include utility methods for common testing scenarios
4. Ensure your mock can be used without additional dependencies
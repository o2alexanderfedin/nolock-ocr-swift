import XCTest
import Foundation
@testable import NolockOCR

// IMPORTANT: This test file uses manual mocks in Tests/Mocks directory.
// For simplicity, we're not using Mockingbird-generated mocks to ensure CI/CD compatibility.

/// OCRProcessingService tests using manual mocks
class OCRProcessingServiceMockingbirdTests: XCTestCase {
    
    // MARK: - Test Properties
    
    // Using shared mock classes from the Mocks directory with prefix to avoid ambiguity
    var mockSession: Tests.Mocks.MockURLSession!
    var mockIO: Tests.Mocks.MockProcessingIO!
    var processingService: OCRProcessingService<Tests.Mocks.MockProcessingIO>!
    
    // Using MockOCRItem and MockProcessingIO from the Mocks directory
    
    // MARK: - Test Data
    
    // Receipt JSON response
    static let mockReceiptResponseJSON = """
    {
        "data": {
            "merchant": {
                "name": "Test Store",
                "address": "123 Test St",
                "phone": "555-123-4567"
            },
            "receiptNumber": "R12345",
            "timestamp": "2025-05-21T14:30:45Z",
            "totals": {
                "subtotal": 10.99,
                "tax": 1.00,
                "total": 11.99
            },
            "currency": "USD",
            "items": [
                {
                    "description": "Test Item 1",
                    "quantity": 1,
                    "unitPrice": 5.99,
                    "totalPrice": 5.99
                },
                {
                    "description": "Test Item 2",
                    "quantity": 2,
                    "unitPrice": 2.50,
                    "totalPrice": 5.00
                }
            ]
        },
        "confidence": {
            "ocr": 0.95,
            "extraction": 0.9,
            "overall": 0.92
        }
    }
    """
    
    // Check JSON response
    static let mockCheckResponseJSON = """
    {
        "data": {
            "checkNumber": "12345",
            "date": "2025-05-21T14:30:45Z",
            "payee": "John Smith",
            "payer": "Test Company",
            "amount": 123.45,
            "amountText": "One hundred twenty-three and 45/100 dollars",
            "memo": "Test payment",
            "bankName": "Test Bank",
            "routingNumber": "123456789",
            "accountNumber": "987654321",
            "signature": true,
            "confidence": 0.95
        },
        "confidence": {
            "ocr": 0.97,
            "extraction": 0.93,
            "overall": 0.95
        }
    }
    """
    
    // Document JSON response
    static let mockDocumentResponseJSON = """
    {
        "documentType": "receipt",
        "data": {
            "merchant": {
                "name": "Auto-Detected Store",
                "address": "456 Auto St",
                "phone": "555-987-6543"
            },
            "receiptNumber": "A98765",
            "timestamp": "2025-05-21T15:45:30Z",
            "totals": {
                "subtotal": 25.50,
                "tax": 2.55,
                "total": 28.05
            },
            "currency": "USD",
            "items": [
                {
                    "description": "Auto Item 1",
                    "quantity": 3,
                    "unitPrice": 8.50,
                    "totalPrice": 25.50
                }
            ]
        },
        "confidence": {
            "ocr": 0.88,
            "extraction": 0.85,
            "overall": 0.87
        }
    }
    """
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        
        // Initialize mock components manually
        mockSession = Tests.Mocks.MockURLSession()
        mockIO = Tests.Mocks.MockProcessingIO()
        
        // Set up OCRClient to use our mock session
        OCRClient.useCustomURLSession(mockSession)
        
        // Set up mock HTTP response
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://ocr-checks-worker.af-4a0.workers.dev/receipt")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        
        // Configure mock session with test data
        mockSession.mockResponse = mockResponse
        mockSession.mockData = OCRProcessingServiceMockingbirdTests.mockReceiptResponseJSON.data(using: .utf8)!
    }
    
    override func tearDown() {
        // Cancel processing to ensure timers are invalidated
        processingService?.cancel()
        
        // Clear references
        mockSession = nil
        mockIO = nil
        processingService = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    /// Test initialization of the service
    func testServiceInitialization() {
        // Create the service
        processingService = OCRProcessingService(
            io: mockIO,
            environment: .production,
            processingInterval: 0.1
        )
        
        XCTAssertNotNil(processingService, "Service should be initialized")
    }
    
    /// Test empty queue behavior
    func testEmptyQueueBehavior() {
        // Create the service
        processingService = OCRProcessingService(
            io: mockIO,
            environment: .production,
            processingInterval: 0.1
        )
        
        // Create expectations
        let expectation = XCTestExpectation(description: "Processing completed")
        
        // Set callback
        processingService.onCompleted = {
            expectation.fulfill()
        }
        
        // Start processing
        processingService.start()
        
        // Wait for expectations
        wait(for: [expectation], timeout: 1.0)
        
        // Verify getNextItemToProcess was called
        XCTAssertGreaterThan(mockIO.getNextItemCallCount, 0, "getNextItemToProcess should be called")
    }
}
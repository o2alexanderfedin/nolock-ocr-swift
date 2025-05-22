import XCTest
import Foundation
@testable import NolockOCR

/// Tests for OCRProcessingService using manual mocks instead of Mockingbird
class OCRProcessingServiceMockingbirdTests: XCTestCase {
    
    // MARK: - Properties
    
    var mockSession: MockURLSession!
    var mockIO: MockProcessingIO!
    var processingService: OCRProcessingService<MockProcessingIO>!
    
    // Mock response data
    let receiptJSON = """
    {
        "data": {
            "merchant": { "name": "Test Store" },
            "receiptNumber": "R12345",
            "timestamp": "2025-05-21T14:30:45Z",
            "totals": { "subtotal": 10.99, "tax": 1.00, "total": 11.99 },
            "currency": "USD"
        },
        "confidence": { "ocr": 0.95, "overall": 0.92 }
    }
    """
    
    let checkJSON = """
    {
        "data": {
            "checkNumber": "12345",
            "date": "2025-05-21T14:30:45Z",
            "payee": "John Smith",
            "amount": 123.45,
            "routingNumber": "123456789",
            "accountNumber": "987654321"
        },
        "confidence": { "ocr": 0.97, "overall": 0.95 }
    }
    """
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        
        // Set up mock URLSession
        mockSession = MockURLSession()
        
        // Set up mock IO
        mockIO = MockProcessingIO()
        
        // Set up OCRClient to use our mock session
        OCRClient.useCustomURLSession(mockSession)
        
        // Set up mock responses
        let receiptData = receiptJSON.data(using: .utf8)!
        let checkData = checkJSON.data(using: .utf8)!
        
        let response = HTTPURLResponse(
            url: URL(string: "https://ocr-checks-worker.af-4a0.workers.dev/receipt")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        
        // Configure the mock session with response data
        mockSession.mockResponse = response
        mockSession.mockData = receiptData
        mockSession.receiptResponseData = receiptData
        mockSession.checkResponseData = checkData
        mockSession.documentResponseData = receiptData // Default to receipt for auto
        
        // Create service
        processingService = OCRProcessingService(
            io: mockIO,
            environment: .production,
            processingInterval: 0.1
        )
    }
    
    override func tearDown() {
        processingService?.cancel()
        mockSession = nil
        mockIO = nil
        processingService = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods
    
    /// Test basic processing with mocked components
    func testBasicProcessing() {
        // Create test item
        let testItem = MockOCRItem(id: "test-item-1", documentType: .receipt)
        mockIO.items = [testItem]
        
        // Create an expectation for completed callback
        let expectation = XCTestExpectation(description: "Processing completed")
        processingService.onCompleted = {
            expectation.fulfill()
        }
        
        // Start processing
        processingService.start()
        
        // Wait for completion
        wait(for: [expectation], timeout: 2.0)
        
        // Verify IO interactions
        XCTAssertEqual(mockIO.getNextItemCallCount, 2) // Once for the item, once for nil
        XCTAssertEqual(mockIO.itemProcessedCallCount, 1) // Called once for the processed item
        XCTAssertEqual(mockIO.processedItems.count, 1)
        
        // Verify we got a success result
        XCTAssertEqual(mockIO.processedResults.count, 1)
        if case .success = mockIO.processedResults.first {
            // Success case as expected
        } else {
            XCTFail("Expected success result")
        }
    }
    
    /// Test service correctly handles errors from getNextItemToProcess
    func testErrorFromGetNextItem() {
        // Configure mock IO to fail on getNextItemToProcess
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        mockIO.shouldFailGetNext = true
        mockIO.customError = testError
        
        // Create an expectation for error status
        let expectation = XCTestExpectation(description: "Error status received")
        
        var receivedError: Error?
        processingService.statusHandler = { status in
            if case let .error(error) = status {
                receivedError = error
                expectation.fulfill()
            }
        }
        
        // Start processing
        processingService.start()
        
        // Wait for error status
        wait(for: [expectation], timeout: 2.0)
        
        // Verify we received the expected error
        XCTAssertNotNil(receivedError)
        let nsError = receivedError as NSError?
        XCTAssertEqual(nsError?.domain, "TestDomain")
        XCTAssertEqual(nsError?.code, 123)
    }
    
    /// Test notifyWorkAvailable functionality
    func testNotifyWorkAvailable() {
        // Configure mock IO to return nil initially, then have items available later
        mockIO.emptyQueueOnFirstCall = true
        let newItem = MockOCRItem(id: "new-item", documentType: .receipt)
        mockIO.setItemsToAddWhenEmpty([newItem])
        
        // Create expectations
        let initialCompletionExpectation = XCTestExpectation(description: "Initial processing completed")
        let secondCompletionExpectation = XCTestExpectation(description: "Second processing completed")
        
        // Set up completion handler for initial empty queue
        processingService.onCompleted = {
            initialCompletionExpectation.fulfill()
            
            // After initial completion, update the completion handler for the second run
            self.processingService.onCompleted = {
                secondCompletionExpectation.fulfill()
            }
            
            // Notify that work is available
            self.processingService.notifyWorkAvailable()
        }
        
        // Start processing with empty queue
        processingService.start()
        
        // Wait for both completions
        wait(for: [initialCompletionExpectation, secondCompletionExpectation], timeout: 3.0)
        
        // Verify interactions
        XCTAssertGreaterThanOrEqual(mockIO.getNextItemCallCount, 3) // At least 3 calls
        XCTAssertEqual(mockIO.processedItems.count, 1) // One item was processed
        XCTAssertEqual(mockIO.processedItems.first?.id, "new-item") // It was our expected item
    }
}
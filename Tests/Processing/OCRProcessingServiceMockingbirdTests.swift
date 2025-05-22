import XCTest
import Foundation
import Mockingbird
@testable import NolockOCR

/// Tests for OCRProcessingService using Mockingbird framework
class OCRProcessingServiceMockingbirdTests: XCTestCase {
    
    // MARK: - Properties
    
    var mockSession: URLSessionProtocolMock!
    var mockIO: OCRProcessingIOMock!
    var processingService: OCRProcessingService<OCRProcessingIOMock>!
    
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
        mockSession = mock(URLSessionProtocol.self)
        
        // Set up mock IO
        mockIO = mock(OCRProcessingIO.self)
        
        // Set up OCRClient to use our mock session
        OCRClient.useCustomURLSession(mockSession)
        
        // Set up mock responses
        let receiptData = receiptJSON.data(using: .utf8)!
        let checkData = checkJSON.data(using: .utf8)!
        
        let receiptResponse = HTTPURLResponse(
            url: URL(string: "https://ocr-checks-worker.af-4a0.workers.dev/receipt")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        
        let checkResponse = HTTPURLResponse(
            url: URL(string: "https://ocr-checks-worker.af-4a0.workers.dev/check")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        
        // Mock data(for:) for receipt URLs
        given(mockSession.data(for: any(), delegate: any()))
            .will { request, _ in
                if let url = request.url?.absoluteString {
                    if url.contains("/receipt") {
                        return (receiptData, receiptResponse)
                    } else if url.contains("/check") {
                        return (checkData, checkResponse)
                    } else if url.contains("/process") {
                        return (receiptData, receiptResponse) // Default to receipt for auto
                    }
                }
                // Default response
                return (receiptData, receiptResponse)
            }
        
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
        // ARRANGE
        // Create test items
        let testItem = TestItem(id: "test-item-1", documentType: .receipt)
        
        // Set up mock IO to return our test item then nil
        given(mockIO.getNextItemToProcess())
            .willReturn(testItem)
            .willReturn(nil)
        
        // Track processed results
        var processedResults: [Result<Any, Error>] = []
        given(mockIO.itemProcessed(item: any(), result: any()))
            .will { _, result in
                if let typedResult = result as? Result<Any, Error> {
                    processedResults.append(typedResult)
                }
            }
        
        // Create an expectation for completed callback
        let expectation = XCTestExpectation(description: "Processing completed")
        processingService.onCompleted = {
            expectation.fulfill()
        }
        
        // ACT
        // Start processing
        processingService.start()
        
        // Wait for completion
        wait(for: [expectation], timeout: 2.0)
        
        // ASSERT
        // Verify getNextItemToProcess was called twice (once for the item, once for nil)
        verify(mockIO.getNextItemToProcess()).wasCalled(exactly(2))
        
        // Verify itemProcessed was called once
        verify(mockIO.itemProcessed(item: any(), result: any())).wasCalled(exactly(1))
        
        // Verify we got a success result
        XCTAssertEqual(processedResults.count, 1)
        if case .success = processedResults.first {
            // Success case as expected
        } else {
            XCTFail("Expected success result")
        }
    }
    
    /// Test service correctly handles errors from getNextItemToProcess
    func testErrorFromGetNextItem() {
        // ARRANGE
        // Create test error
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // Set up mock IO to throw an error
        given(mockIO.getNextItemToProcess())
            .willThrow(testError)
        
        // Create an expectation for error status
        let expectation = XCTestExpectation(description: "Error status received")
        
        var receivedError: Error?
        processingService.statusHandler = { status in
            if case let .error(error) = status {
                receivedError = error
                expectation.fulfill()
            }
        }
        
        // ACT
        // Start processing
        processingService.start()
        
        // Wait for error status
        wait(for: [expectation], timeout: 2.0)
        
        // ASSERT
        // Verify getNextItemToProcess was called
        verify(mockIO.getNextItemToProcess()).wasCalled()
        
        // Verify we received the expected error
        XCTAssertNotNil(receivedError)
        let nsError = receivedError as NSError?
        XCTAssertEqual(nsError?.domain, "TestDomain")
        XCTAssertEqual(nsError?.code, 123)
    }
    
    /// Test notifyWorkAvailable functionality
    func testNotifyWorkAvailable() {
        // ARRANGE
        // Set up mock IO to return nil initially, then an item when called again
        let testItem = TestItem(id: "new-item", documentType: .receipt)
        
        given(mockIO.getNextItemToProcess())
            .willReturn(nil)
            .willReturn(testItem)
            .willReturn(nil)
        
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
        
        // ACT
        // Start processing with empty queue
        processingService.start()
        
        // Wait for both completions
        wait(for: [initialCompletionExpectation, secondCompletionExpectation], timeout: 3.0)
        
        // ASSERT
        // Verify getNextItemToProcess was called at least 3 times
        verify(mockIO.getNextItemToProcess()).wasCalled(atLeast(3))
        
        // Verify itemProcessed was called once with the new item
        verify(mockIO.itemProcessed(item: any(), result: any())).wasCalled(exactly(1))
    }
}

// MARK: - Helper Types

/// Test implementation of OCRProcessable for testing
class TestItem: OCRProcessable, Identifiable {
    let id: String
    let imageData: Data
    let documentType: DocumentType
    var metadata: [String: Any]
    
    init(id: String, documentType: DocumentType = .receipt, metadata: [String: Any] = [:]) {
        self.id = id
        self.documentType = documentType
        self.metadata = metadata
        
        // Create mock image data
        var data = Data(capacity: 1024)
        for i in 0..<1024 {
            data.append(UInt8(i % 256))
        }
        self.imageData = data
    }
}
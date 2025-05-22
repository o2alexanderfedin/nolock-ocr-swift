import XCTest
import Foundation
@testable import NolockOCR
import Mockingbird

/// OCRProcessingService tests using Mockingbird for mocking
class OCRProcessingServiceMockingbirdTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var mockSession: URLSessionProtocolMock!
    var mockIO: OCRProcessingIOMock<MockOCRItem>!
    var processingService: OCRProcessingService<OCRProcessingIOMock<MockOCRItem>>!
    
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
        
        // Initialize mocks
        mockSession = mock(URLSessionProtocol.self)
        mockIO = mock(OCRProcessingIO.self) as? OCRProcessingIOMock<MockOCRItem>
        
        // Set up OCRClient to use our mock session
        OCRClient.useCustomURLSession(mockSession)
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
    
    // MARK: - Helper Methods
    
    /// Create a processing service with the specified parameters
    private func createService(
        processingInterval: TimeInterval = 0.1
    ) -> OCRProcessingService<OCRProcessingIOMock<MockOCRItem>> {
        return OCRProcessingService(
            io: mockIO,
            environment: .production,
            processingInterval: processingInterval
        )
    }
    
    /// Creates a mock HTTP response for testing
    private func createMockResponse(path: String) -> HTTPURLResponse {
        return HTTPURLResponse(
            url: URL(string: "https://ocr-checks-worker.af-4a0.workers.dev\(path)")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
    }
    
    /// Creates a mock item with specified document type
    private func createMockItem(id: String, type: DocumentType) -> MockOCRItem {
        return MockOCRItem(
            id: id,
            imageData: Data(repeating: 0, count: 1024),
            documentType: type
        )
    }
    
    // MARK: - Tests
    
    /// Test initialization of the service
    func testServiceInitialization() {
        processingService = createService()
        XCTAssertNotNil(processingService)
    }
    
    /// Test empty queue behavior
    func testEmptyQueueBehavior() {
        // ARRANGE
        // Set up IO mock to return nil (empty queue)
        given(mockIO.getNextItemToProcess()).willReturn(nil)
        
        // Create expectations
        let expectation = XCTestExpectation(description: "Processing completed")
        
        // SETUP service
        processingService = createService()
        
        // Set callback
        processingService.onCompleted = {
            expectation.fulfill()
        }
        
        // ACT
        // Start processing
        processingService.start()
        
        // ASSERT
        // Wait for expectations
        wait(for: [expectation], timeout: 1.0)
        
        // Verify getNextItemToProcess was called
        verify(mockIO.getNextItemToProcess()).wasCalled()
    }
    
    /// Test different document types are processed correctly
    func testDocumentTypeProcessing() {
        // ARRANGE
        // Create test items for each document type
        let receiptItem = createMockItem(id: "test-receipt", type: .receipt)
        let checkItem = createMockItem(id: "test-check", type: .check)
        let autoItem = createMockItem(id: "test-auto", type: .auto)
        
        // Set up expectations for mock IO
        // Return different items in sequence
        given(mockIO.getNextItemToProcess())
            .willReturn(receiptItem) // First call
            .willReturn(checkItem)   // Second call
            .willReturn(autoItem)    // Third call
            .willReturn(nil)         // Fourth call (end processing)
        
        // Mock IO will accept processed results
        given(mockIO.itemProcessed(item: any(), result: any())).willReturn(())
        
        // Set up session responses
        let receiptData = Self.mockReceiptResponseJSON.data(using: .utf8)!
        let receiptResponse = createMockResponse(path: "/receipt")
        
        let checkData = Self.mockCheckResponseJSON.data(using: .utf8)!
        let checkResponse = createMockResponse(path: "/check")
        
        let documentData = Self.mockDocumentResponseJSON.data(using: .utf8)!
        let documentResponse = createMockResponse(path: "/process")
        
        // Mock session responses based on URL pattern
        given(mockSession.data(for: where { $0.url?.path.contains("/receipt") ?? false }, delegate: any()))
            .willReturn((receiptData, receiptResponse))
        
        given(mockSession.data(for: where { $0.url?.path.contains("/check") ?? false }, delegate: any()))
            .willReturn((checkData, checkResponse))
        
        given(mockSession.data(for: where { $0.url?.path.contains("/process") ?? false }, delegate: any()))
            .willReturn((documentData, documentResponse))
        
        // Create expectations
        let expectation = XCTestExpectation(description: "Processing completed")
        
        // Set up service
        processingService = createService()
        
        // Set callbacks
        processingService.onCompleted = {
            expectation.fulfill()
        }
        
        // ACT
        // Start processing
        processingService.start()
        
        // ASSERT
        // Wait for expectations
        wait(for: [expectation], timeout: 3.0)
        
        // Verify getNextItemToProcess was called 4 times (3 items + 1 nil return)
        verify(mockIO.getNextItemToProcess()).wasCalled(times: 4)
        
        // Verify itemProcessed was called for each item
        verify(mockIO.itemProcessed(item: receiptItem, result: any())).wasCalled()
        verify(mockIO.itemProcessed(item: checkItem, result: any())).wasCalled()
        verify(mockIO.itemProcessed(item: autoItem, result: any())).wasCalled()
        
        // Verify the correct endpoints were called
        verify(mockSession.data(for: where { $0.url?.path.contains("/receipt") ?? false }, delegate: any())).wasCalled()
        verify(mockSession.data(for: where { $0.url?.path.contains("/check") ?? false }, delegate: any())).wasCalled()
        verify(mockSession.data(for: where { $0.url?.path.contains("/process") ?? false }, delegate: any())).wasCalled()
    }
    
    /// Test notifyWorkAvailable functionality
    func testNotifyWorkAvailable() {
        // ARRANGE
        // Create test items
        let newItem = createMockItem(id: "new-item", type: .receipt)
        
        // Set up expectations for mock IO
        // Return nil first (empty queue), then return an item when called again
        given(mockIO.getNextItemToProcess())
            .willReturn(nil)    // First call - empty queue
            .willReturn(newItem) // Second call - after notification
            .willReturn(nil)    // Third call - empty again after processing
        
        // Mock IO will accept processed results
        given(mockIO.itemProcessed(item: any(), result: any())).willReturn(())
        
        // Set up session responses
        let receiptData = Self.mockReceiptResponseJSON.data(using: .utf8)!
        let receiptResponse = createMockResponse(path: "/receipt")
        
        // Mock session responses
        given(mockSession.data(for: any(), delegate: any()))
            .willReturn((receiptData, receiptResponse))
        
        // Create expectations
        let initialCompletionExpectation = XCTestExpectation(description: "Initial processing completed")
        let secondCompletionExpectation = XCTestExpectation(description: "Second processing completed")
        
        // Set up tracking variable for completion calls
        var completionCount = 0
        
        // Set up service
        processingService = createService()
        
        // Set callbacks
        processingService.onCompleted = {
            completionCount += 1
            if completionCount == 1 {
                initialCompletionExpectation.fulfill()
            } else {
                secondCompletionExpectation.fulfill()
            }
        }
        
        // ACT - PHASE 1
        // Start processing with empty queue
        processingService.start()
        
        // Wait for initial completion
        wait(for: [initialCompletionExpectation], timeout: 1.0)
        
        // ACT - PHASE 2
        // Notify that work is available
        processingService.notifyWorkAvailable()
        
        // Wait for second completion
        wait(for: [secondCompletionExpectation], timeout: 1.0)
        
        // ASSERT
        // Verify getNextItemToProcess was called 3 times
        verify(mockIO.getNextItemToProcess()).wasCalled(times: 3)
        
        // Verify itemProcessed was called once with the new item
        verify(mockIO.itemProcessed(item: newItem, result: any())).wasCalled()
        
        // Verify the correct endpoint was called
        verify(mockSession.data(for: any(), delegate: any())).wasCalled()
    }
    
    /// Test handling of pending work counter
    func testPendingWorkCounter() {
        // ARRANGE
        // Create test items
        let initialItem = createMockItem(id: "initial-item", type: .receipt)
        let pendingItem1 = createMockItem(id: "pending-1", type: .receipt)
        let pendingItem2 = createMockItem(id: "pending-2", type: .receipt)
        
        // Set up expectations for mock IO
        given(mockIO.getNextItemToProcess())
            .willReturn(initialItem) // First item
            .willReturn(pendingItem1) // Second item
            .willReturn(pendingItem2) // Third item
            .willReturn(nil)         // No more items
        
        // Mock IO will accept processed results
        given(mockIO.itemProcessed(item: any(), result: any())).willReturn(())
        
        // Set up session responses
        let receiptData = Self.mockReceiptResponseJSON.data(using: .utf8)!
        let receiptResponse = createMockResponse(path: "/receipt")
        
        // Mock session responses
        given(mockSession.data(for: any(), delegate: any()))
            .willReturn((receiptData, receiptResponse))
        
        // Create expectations
        let expectation = XCTestExpectation(description: "Processing completed")
        
        // Track status changes
        var statusChanges: [OCRProcessingService<OCRProcessingIOMock<MockOCRItem>>.ProcessingStatus] = []
        
        // Set up service with a longer interval to control timing
        processingService = createService(processingInterval: 0.5)
        
        // Set up status handler
        processingService.statusHandler = { status in
            statusChanges.append(status)
            
            // When we've processed all items and see a completion status, fulfill the expectation
            if case .completed = status, statusChanges.count > 3 {
                expectation.fulfill()
            }
        }
        
        // ACT
        // Start processing
        processingService.start()
        
        // Add pending work notification after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Notify about more work while processing is happening
            self.processingService.notifyWorkAvailable()
            self.processingService.notifyWorkAvailable() // Call twice to increase counter
        }
        
        // ASSERT
        // Wait for completion
        wait(for: [expectation], timeout: 3.0)
        
        // Verify all items were processed
        verify(mockIO.itemProcessed(item: initialItem, result: any())).wasCalled()
        verify(mockIO.itemProcessed(item: pendingItem1, result: any())).wasCalled()
        verify(mockIO.itemProcessed(item: pendingItem2, result: any())).wasCalled()
        
        // Verify we saw appropriate status changes (processing counts should reflect pending work)
        var sawPendingWorkInStatus = false
        for status in statusChanges {
            if case let .processing(_, total) = status {
                if total > 1 {
                    sawPendingWorkInStatus = true
                    break
                }
            }
        }
        
        XCTAssertTrue(sawPendingWorkInStatus, "Status should have reflected pending work")
    }
    
    /// Test processing items with mock HTTP responses
    func testProcessingWithMockResponses() {
        // ARRANGE
        // Create test items
        let receiptItem = createMockItem(id: "test-receipt", type: .receipt)
        let checkItem = createMockItem(id: "test-check", type: .check)
        
        // Set up IO mock to return our test items then nil
        given(mockIO.getNextItemToProcess())
            .willReturn(receiptItem)
            .willReturn(checkItem)
            .willReturn(nil)
        
        // Mock data storage
        var processedResults: [Result<Any, Error>] = []
        
        // Track results from itemProcessed calls
        given(mockIO.itemProcessed(item: any(), result: any()))
            .will { item, result in
                if let result = result as? Result<Any, Error> {
                    processedResults.append(result)
                }
                return ()
            }
        
        // Set up session responses
        let receiptData = Self.mockReceiptResponseJSON.data(using: .utf8)!
        let receiptResponse = createMockResponse(path: "/receipt")
        
        let checkData = Self.mockCheckResponseJSON.data(using: .utf8)!
        let checkResponse = createMockResponse(path: "/check")
        
        // Mock session responses based on URL pattern
        given(mockSession.data(for: where { $0.url?.path.contains("/receipt") ?? false }, delegate: any()))
            .willReturn((receiptData, receiptResponse))
        
        given(mockSession.data(for: where { $0.url?.path.contains("/check") ?? false }, delegate: any()))
            .willReturn((checkData, checkResponse))
        
        // Create expectations
        let expectation = XCTestExpectation(description: "Processing completed")
        
        // Set up service
        processingService = createService()
        
        // Set callbacks
        processingService.onCompleted = {
            expectation.fulfill()
        }
        
        // ACT
        // Start processing
        processingService.start()
        
        // ASSERT
        // Wait for expectations
        wait(for: [expectation], timeout: 2.0)
        
        // Verify mock IO methods were called the expected number of times
        verify(mockIO.getNextItemToProcess()).wasCalled(times: 3)
        verify(mockIO.itemProcessed(item: any(), result: any())).wasCalled(times: 2)
        
        // Verify we received the correct number of results
        XCTAssertEqual(processedResults.count, 2)
        
        // Verify results are success cases
        for result in processedResults {
            switch result {
            case .success:
                // This is what we expect
                break
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
        }
    }
}

/// Mock implementation of OCRProcessable for testing
class MockOCRItem: OCRProcessable, Identifiable {
    let id: String
    let imageData: Data
    let documentType: DocumentType
    var metadata: [String: Any]
    
    init(id: String, 
         imageData: Data = Data(repeating: 0, count: 1024), 
         documentType: DocumentType = .receipt,
         metadata: [String: Any] = [:]) {
        self.id = id
        self.imageData = imageData
        self.documentType = documentType
        self.metadata = metadata
    }
}
import XCTest
import Foundation
@testable import NolockOCR
import Mockingbird

/// Example showing how to refactor OCRProcessingServiceTests using Mockingbird
class MockingbirdExampleTests: XCTestCase {
    
    // MARK: - Properties
    
    var mockSession: URLSessionProtocolMock!
    var mockIO: OCRProcessingIOMock<MockOCRItem>!
    var processingService: OCRProcessingService<OCRProcessingIOMock<MockOCRItem>>!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        mockSession = mock(URLSessionProtocol.self)
        
        // Set up mock IO
        mockIO = mock(OCRProcessingIO.self) as? OCRProcessingIOMock<MockOCRItem>
        
        // Set up OCRClient to use our mock session
        OCRClient.useCustomURLSession(mockSession)
        
        // Sample test data
        let receiptJSON = """
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
        let receiptData = receiptJSON.data(using: .utf8)!
        
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://ocr-checks-worker.af-4a0.workers.dev/receipt")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        
        // Create the processing service
        processingService = OCRProcessingService(
            io: mockIO,
            environment: .production,
            processingInterval: 0.1
        )
    }
    
    override func tearDown() {
        mockSession = nil
        mockIO = nil
        processingService = nil
        super.tearDown()
    }
    
    // MARK: - Test Examples
    
    /// Example test using Mockingbird for mocking and verification
    func testProcessItemWithMockingbird() async throws {
        // ARRANGE
        // Create test item
        let testItem = MockOCRItem(id: "test-receipt", documentType: .receipt)
        
        // Set up response data
        let responseData = """
        {
            "data": {
                "merchant": {
                    "name": "Test Store",
                    "address": "123 Test St"
                },
                "totals": {
                    "subtotal": 10.99,
                    "tax": 1.00,
                    "total": 11.99
                },
                "currency": "USD",
                "items": []
            },
            "confidence": {
                "ocr": 0.95,
                "extraction": 0.9,
                "overall": 0.92
            }
        }
        """.data(using: .utf8)!
        
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://ocr-checks-worker.af-4a0.workers.dev/receipt")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        
        // Set up expectations for mock IO
        given(mockIO.getNextItemToProcess()).willReturn(testItem)
        given(mockIO.itemProcessed(item: any(), result: any())).willReturn(())
        
        // Set up expectations for mock session
        given(mockSession.data(for: any(), delegate: any()))
            .willReturn((responseData, mockResponse))
        
        // Create expectations
        let expectation = XCTestExpectation(description: "Processing completed")
        
        // Set up completion handler
        processingService.onCompleted = {
            expectation.fulfill()
        }
        
        // ACT
        // Start processing
        processingService.start()
        
        // Wait for processing to complete
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // ASSERT
        // Verify that the session was called with a request to the receipt endpoint
        verify(mockSession.data(for: where { request in
            guard let url = request.url else { return false }
            return url.absoluteString.contains("/receipt")
        }, delegate: any())).wasCalled()
        
        // Verify that itemProcessed was called on the IO
        verify(mockIO.itemProcessed(item: where { item in
            return item.id == "test-receipt"
        }, result: any())).wasCalled()
    }
    
    /// Example test for notifyWorkAvailable functionality
    func testNotifyWorkAvailableWithMockingbird() async throws {
        // ARRANGE
        // First return nil (empty queue), then return a new item when called again
        let newItem = MockOCRItem(id: "new-item", documentType: .receipt)
        
        given(mockIO.getNextItemToProcess())
            .willReturn(nil)  // First call returns nil
            .willReturn(newItem)  // Second call returns the new item
        
        given(mockIO.itemProcessed(item: any(), result: any())).willReturn(())
        
        // Set up response for mock session
        let responseData = """
        {
            "data": {
                "merchant": {
                    "name": "Test Store"
                },
                "totals": {
                    "total": 11.99
                }
            },
            "confidence": {
                "overall": 0.92
            }
        }
        """.data(using: .utf8)!
        
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://ocr-checks-worker.af-4a0.workers.dev/receipt")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        
        given(mockSession.data(for: any(), delegate: any()))
            .willReturn((responseData, mockResponse))
        
        // Create expectations
        let initialCompletionExpectation = XCTestExpectation(description: "Initial processing completed")
        let secondCompletionExpectation = XCTestExpectation(description: "Second processing completed")
        
        // Set callbacks
        var completionCount = 0
        processingService.onCompleted = {
            completionCount += 1
            if completionCount == 1 {
                initialCompletionExpectation.fulfill()
            } else {
                secondCompletionExpectation.fulfill()
            }
        }
        
        // ACT
        // Start processing with empty queue
        processingService.start()
        
        // Wait for initial completion
        await fulfillment(of: [initialCompletionExpectation], timeout: 1.0)
        
        // Notify that work is available
        processingService.notifyWorkAvailable()
        
        // Wait for second completion
        await fulfillment(of: [secondCompletionExpectation], timeout: 1.0)
        
        // ASSERT
        // Verify getNextItemToProcess was called twice
        verify(mockIO.getNextItemToProcess()).wasCalled(times: 2)
        
        // Verify itemProcessed was called once with the new item
        verify(mockIO.itemProcessed(item: where { item in
            return item.id == "new-item"
        }, result: any())).wasCalled()
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
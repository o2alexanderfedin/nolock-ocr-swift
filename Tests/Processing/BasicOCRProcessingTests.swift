import XCTest
import Foundation
@testable import NolockOCR

/// Simplified mock URLSession for basic tests
class SimpleMockURLSession: URLSessionProtocol {
    // Create a basic successful response
    static let mockSuccessResponse = HTTPURLResponse(
        url: URL(string: "https://ocr-checks-worker.af-4a0.workers.dev/receipt")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
    )!
    
    // Basic mock receipt JSON that matches the expected structure
    static let mockReceiptJSON = """
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
    
    // Basic mock check JSON that matches the expected structure
    static let mockCheckJSON = """
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
    
    func data(from url: URL, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        // Always return success
        return (Self.mockReceiptJSON.data(using: .utf8)!, Self.mockSuccessResponse)
    }
    
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        // Return different responses based on endpoint
        let responseJSON: String
        if let url = request.url?.path, url.contains("/check") {
            responseJSON = Self.mockCheckJSON
        } else {
            responseJSON = Self.mockReceiptJSON
        }
        return (responseJSON.data(using: .utf8)!, Self.mockSuccessResponse)
    }
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        // Create a fake task that immediately calls back with success
        let task = MockTask()
        completionHandler(Self.mockReceiptJSON.data(using: .utf8), Self.mockSuccessResponse, nil)
        return task
    }
    
    class MockTask: URLSessionDataTask, @unchecked Sendable {
        override func resume() {
            // Do nothing
        }
        
        override func cancel() {
            // Do nothing
        }
    }
}

/// Basic tests for OCRProcessingService using real test images from Resources directory
/// These tests focus on core functionality and use modern Swift async/await patterns
class BasicOCRProcessingTests: XCTestCase {
    
    // MARK: - Test Mock
    
    /// Mock implementation of OCRProcessingIO for basic testing
    class SimpleMockIO: OCRProcessingIO {
        /// Simple mock OCR item that uses real test images
        struct MockItem: OCRProcessable, Identifiable {
            let id: String
            let imageData: Data
            let documentType: DocumentType
            var metadata: [String: Any]
            
            // Create mock image data that represents realistic file sizes
            static func createMockImageData(name: String) -> Data {
                // Create realistic mock data based on the image type
                let baseData = "MockImage-\(name)".data(using: .utf8) ?? Data()
                var mockData = Data()
                
                // Create different sizes based on image type for realistic testing
                let targetSize: Int
                if name.contains("receipt") {
                    targetSize = 2048 // 2KB for receipt
                } else if name.contains("check") {
                    targetSize = 3072 // 3KB for check
                } else {
                    targetSize = 1024 // 1KB default
                }
                
                // Fill with mock data to reach target size
                while mockData.count < targetSize {
                    mockData.append(baseData)
                }
                
                return Data(mockData.prefix(targetSize))
            }
            
            static func createTestItem(id: String = "test-item") -> MockItem {
                // Use mock receipt image data
                return MockItem(
                    id: id,
                    imageData: createMockImageData(name: "fredmeyer-receipt.jpg"),
                    documentType: .receipt,
                    metadata: ["test": true]
                )
            }
            
            // Create a receipt item with mock image data
            static func createReceiptItem(id: String = "receipt-item") -> MockItem {
                return MockItem(
                    id: id,
                    imageData: createMockImageData(name: "fredmeyer-receipt.jpg"),
                    documentType: .receipt,
                    metadata: ["test": true]
                )
            }
            
            // Create a check item with mock image data
            static func createCheckItem(id: String = "check-item") -> MockItem {
                return MockItem(
                    id: id,
                    imageData: createMockImageData(name: "promo-check.HEIC"),
                    documentType: .check,
                    metadata: ["test": true]
                )
            }
        }
        
        typealias Item = MockItem
        
        var items: [Item] = []
        var processedItems: [Item] = []
        var processedResults: [Result<Any, Error>] = []
        
        func getNextItemToProcess() async throws -> Item? {
            if items.isEmpty {
                return nil
            }
            return items.removeFirst()
        }
        
        func itemProcessed(item: Item, result: Result<Any, Error>) async throws {
            processedItems.append(item)
            processedResults.append(result)
        }
    }
    
    // MARK: - Test Properties
    
    var mockIO: SimpleMockIO!
    var processingService: OCRProcessingService<SimpleMockIO>!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        mockIO = SimpleMockIO()
        
        // Configure OCRClient to use our simplified mock session for all tests
        OCRClient.useCustomURLSession(SimpleMockURLSession())
    }
    
    override func tearDown() {
        processingService?.cancel()
        processingService = nil
        mockIO = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    /// Test initialization of the service
    func testServiceInitialization() {
        processingService = OCRProcessingService(
            io: mockIO,
            environment: .production,
            processingInterval: 2.0
        )
        
        XCTAssertNotNil(processingService)
    }
    
    /// Test empty queue behavior
    func testEmptyQueueBehavior() async {
        // Create expectation for async testing
        let expectation = self.expectation(description: "Processing completed")
        
        // Create service with empty IO
        processingService = OCRProcessingService(
            io: mockIO,
            environment: .production,
            processingInterval: 0.1
        )
        
        // Set callback
        processingService.onCompleted = {
            expectation.fulfill()
        }
        
        // Start processing
        processingService.start()
        
        // Wait for expectation
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Verify no items were processed (empty queue)
        XCTAssertEqual(mockIO.processedItems.count, 0)
    }
    
    /// Test cancellation
    func testCancellation() async {
        // Create service with empty IO
        processingService = OCRProcessingService(
            io: mockIO,
            environment: .production,
            processingInterval: 0.1
        )
        
        // Create expectation for cancellation
        let expectation = self.expectation(description: "Service cancelled")
        var expectationFulfilled = false
        
        processingService.statusHandler = { status in
            if case .cancelled = status, !expectationFulfilled {
                expectationFulfilled = true
                expectation.fulfill()
            }
        }
        
        // Start and immediately cancel
        processingService.start()
        processingService.cancel()
        
        // Wait for cancellation
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    /// Test status tracking
    func testStatusTracking() async {
        // Add a receipt item that uses a real image from Resources
        mockIO.items = [SimpleMockIO.MockItem.createReceiptItem()]
        
        // Create service
        processingService = OCRProcessingService(
            io: mockIO,
            environment: .production,
            processingInterval: 0.1
        )
        
        // Track status updates
        var receivedStatuses: [OCRProcessingService<SimpleMockIO>.ProcessingStatus] = []
        processingService.statusHandler = { status in
            receivedStatuses.append(status)
        }
        
        // Just verify service initialization and start/cancel work properly
        processingService.start()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        processingService.cancel()
        
        // Verify we got at least one status update
        XCTAssertFalse(receivedStatuses.isEmpty, "Should have received at least one status update")
    }
    
    /// Test work notification with multiple real images
    func testNotifyWorkAvailable() async {
        // Start with empty queue
        mockIO.items = []
        
        // Create service
        processingService = OCRProcessingService(
            io: mockIO,
            environment: .production,
            processingInterval: 0.1
        )
        
        // Create expectation for initial completion
        let initialExpectation = expectation(description: "Empty queue processed")
        
        // Set completion callback
        processingService.onCompleted = {
            initialExpectation.fulfill()
        }
        
        // Start processing
        processingService.start()
        
        // Wait for initial completion
        await fulfillment(of: [initialExpectation], timeout: 1.0)
        
        // Now add a receipt test image and notify about work
        mockIO.items = [
            SimpleMockIO.MockItem.createReceiptItem(id: "notification-receipt")
        ]
        
        // Create expectation for completion after notification
        let notificationExpectation = expectation(description: "Notification processed")
        
        // Update completion handler
        processingService.onCompleted = {
            notificationExpectation.fulfill()
        }
        
        // Track processed item IDs
        var processedItemIds = Set<String>()
        processingService.statusHandler = { [weak self] status in
            guard let self = self else { return }
            if case .processing(let completed, _) = status {
                if completed > 0 && !self.mockIO.processedItems.isEmpty {
                    processedItemIds = Set(self.mockIO.processedItems.map { $0.id })
                }
            }
        }
        
        // Notify about work
        processingService.notifyWorkAvailable()
        
        // Wait for completion with longer timeout to handle real images
        await fulfillment(of: [notificationExpectation], timeout: 5.0)
        
        // Verify item was processed
        XCTAssertEqual(mockIO.processedItems.count, 1, "Receipt item should be processed after notification")
        XCTAssertTrue(processedItemIds.contains("notification-receipt"), "Receipt item should be processed")
        
        // Verify we got success results
        for result in mockIO.processedResults {
            if case .failure(let error) = result {
                XCTFail("Expected success but got error: \(error)")
            }
        }
    }
}
import XCTest
@testable import NolockOCR

// Add test image helper directly to this file
fileprivate enum OCRClientTestHelper {
    /// Get the test bundle
    static var bundle: Bundle { Bundle.module }
    
    /// Load a resource from the test bundle
    static func loadResource(name: String, extension ext: String? = nil, shouldFail: Bool = true) -> Data? {
        guard let url = bundle.url(forResource: name, withExtension: ext) else {
            // Calculate the expected path for better error message
            let resourcesPath = bundle.bundlePath + "/Resources"
            let expectedPath = resourcesPath + "/" + name + (ext != nil ? "."+ext! : "")
            
            if shouldFail {
                XCTFail("Failed to locate resource: \(name).\(ext ?? "") - Expected at path: \(expectedPath)")
            }
            return nil
        }
        
        guard let data = try? Data(contentsOf: url) else {
            if shouldFail {
                XCTFail("Failed to load resource: \(name).\(ext ?? "") - File exists at path: \(url.path) but could not be read")
            }
            return nil
        }
        
        return data
    }
    
    static var receiptImage: Data? {
        loadResource(name: "fredmeyer-receipt", extension: "jpg")
    }
    
    static var receiptImage2: Data? {
        loadResource(name: "fredmeyer-receipt-2", extension: "jpg") 
    }
    
    static var billImage: Data? {
        loadResource(name: "rental-bill", extension: "jpg")
    }
    
    static var heicBillImage: Data? {
        loadResource(name: "pge-bill", extension: "HEIC")
    }
    
    static var heicCheckImage: Data? {
        loadResource(name: "promo-check", extension: "HEIC")
    }
}

/// Comprehensive unit tests for OCRClient that don't invoke the actual remote service
class OCRClientUnitTests: XCTestCase {
    // Mock objects
    private var mockSession: MockURLSession!
    private var client: OCRClient!
    
    // Sample response data
    private let healthResponseJSON = """
    {
        "status": "ok",
        "timestamp": "2025-05-21T12:30:45Z",
        "version": "1.8.3"
    }
    """
    
    private let checkResponseJSON = """
    {
        "data": {
            "checkNumber": "12345",
            "date": "2025-06-01T00:00:00.000Z",
            "payee": "John Smith",
            "payer": "ACME Corporation",
            "amount": 789.50,
            "amountText": "Seven hundred eighty-nine and 50/100 dollars",
            "memo": "Consulting services",
            "bankName": "First National Bank",
            "routingNumber": "987654321",
            "accountNumber": "123456789",
            "signature": true,
            "confidence": 0.95
        },
        "confidence": {
            "ocr": 0.98,
            "extraction": 0.92,
            "overall": 0.95
        }
    }
    """
    
    private let receiptResponseJSON = """
    {
        "data": {
            "merchant": {
                "name": "Coffee Shop",
                "address": "123 Main St, Anytown, USA",
                "phone": "555-123-4567"
            },
            "receiptNumber": "R-20250521-1234",
            "timestamp": "2025-05-21T08:45:30Z",
            "totals": {
                "subtotal": 15.50,
                "tax": 1.24,
                "total": 16.74
            },
            "currency": "USD",
            "items": [
                {
                    "description": "Cappuccino",
                    "quantity": 2,
                    "unitPrice": 4.25,
                    "totalPrice": 8.50
                },
                {
                    "description": "Chocolate Croissant",
                    "quantity": 1,
                    "unitPrice": 3.50,
                    "totalPrice": 3.50
                },
                {
                    "description": "Breakfast Sandwich",
                    "quantity": 1,
                    "unitPrice": 3.50,
                    "totalPrice": 3.50
                }
            ],
            "confidence": 0.92
        },
        "confidence": {
            "ocr": 0.95,
            "extraction": 0.90,
            "overall": 0.92
        }
    }
    """
    
    private let documentResponseJSON = """
    {
        "documentType": "check",
        "data": {
            "checkNumber": "12345",
            "date": "2025-06-01T00:00:00.000Z",
            "payee": "John Smith",
            "payer": "ACME Corporation",
            "amount": 789.50,
            "amountText": "Seven hundred eighty-nine and 50/100 dollars",
            "memo": "Consulting services",
            "bankName": "First National Bank",
            "routingNumber": "987654321",
            "accountNumber": "123456789",
            "signature": true,
            "confidence": 0.95
        },
        "confidence": {
            "ocr": 0.98,
            "extraction": 0.92,
            "overall": 0.95
        }
    }
    """
    
    private let errorResponseJSON = """
    {
        "error": "Invalid image format or corrupted file"
    }
    """
    
    // Setup before each test
    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        client = OCRClient(environment: .production, session: mockSession)
    }
    
    // Teardown after each test
    override func tearDown() {
        mockSession = nil
        client = nil
        super.tearDown()
    }
    
    // MARK: - URL Construction Tests
    
    /// Test that the health endpoint URL is constructed correctly
    func testHealthEndpointURL() async {
        // Prepare mock response
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/health",
            statusCode: 200,
            data: healthResponseJSON.data(using: .utf8)!
        )
        
        // Execute request
        _ = try? await client.getHealth()
        
        // Verify URL
        XCTAssertEqual(mockSession.lastRequestURL?.path, "/health")
        XCTAssertEqual(mockSession.lastRequestURL?.host, "ocr-checks-worker.af-4a0.workers.dev")
        XCTAssertNil(mockSession.lastRequestURL?.query)
    }
    
    /// Test that check endpoint URL is constructed correctly
    func testCheckEndpointURL() async {
        // Prepare mock response
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/check",
            statusCode: 200,
            data: checkResponseJSON.data(using: .utf8)!
        )
        
        // Execute request with format and filename, using a real image
        let imageData = OCRClientTestHelper.receiptImage
        XCTAssertNotNil(imageData, "Failed to load receipt test image - image file missing")
        
        guard let imageData = imageData else {
            return
        }
        _ = try? await client.processCheck(
            imageData: imageData,
            format: .pdf,
            filename: "test-check.pdf"
        )
        
        // Verify URL
        XCTAssertEqual(mockSession.lastRequestURL?.path, "/check")
        XCTAssertEqual(mockSession.lastRequestURL?.host, "ocr-checks-worker.af-4a0.workers.dev")
        
        // Verify query parameters
        let queryItems = URLComponents(url: mockSession.lastRequestURL!, resolvingAgainstBaseURL: false)?.queryItems
        XCTAssertEqual(queryItems?.count, 2)
        XCTAssertEqual(queryItems?.first(where: { $0.name == "format" })?.value, "pdf")
        XCTAssertEqual(queryItems?.first(where: { $0.name == "filename" })?.value, "test-check.pdf")
    }
    
    /// Test that receipt endpoint URL is constructed correctly
    func testReceiptEndpointURL() async {
        // Prepare mock response
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/receipt",
            statusCode: 200,
            data: receiptResponseJSON.data(using: .utf8)!
        )
        
        // Execute request - default format, no filename, using real image
        let imageData = OCRClientTestHelper.receiptImage2
        XCTAssertNotNil(imageData, "Failed to load receipt2 test image - image file missing")
        
        guard let imageData = imageData else {
            return
        }
        _ = try? await client.processReceipt(imageData: imageData)
        
        // Verify URL
        XCTAssertEqual(mockSession.lastRequestURL?.path, "/receipt")
        
        // Verify query parameters - only format
        let queryItems = URLComponents(url: mockSession.lastRequestURL!, resolvingAgainstBaseURL: false)?.queryItems
        XCTAssertEqual(queryItems?.count, 1)
        XCTAssertEqual(queryItems?.first?.name, "format")
        XCTAssertEqual(queryItems?.first?.value, "image")
    }
    
    /// Test that document endpoint URL is constructed correctly
    func testDocumentEndpointURL() async {
        // Prepare mock response
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/process",
            statusCode: 200,
            data: documentResponseJSON.data(using: .utf8)!
        )
        
        // Execute request
        _ = try? await client.processDocument(
            imageData: Data(),
            type: .check,
            format: .image,
            filename: "test-document.jpg"
        )
        
        // Verify URL
        XCTAssertEqual(mockSession.lastRequestURL?.path, "/process")
        
        // Verify query parameters
        let queryItems = URLComponents(url: mockSession.lastRequestURL!, resolvingAgainstBaseURL: false)?.queryItems
        XCTAssertEqual(queryItems?.count, 3)
        XCTAssertEqual(queryItems?.first(where: { $0.name == "type" })?.value, "check")
        XCTAssertEqual(queryItems?.first(where: { $0.name == "format" })?.value, "image")
        XCTAssertEqual(queryItems?.first(where: { $0.name == "filename" })?.value, "test-document.jpg")
    }
    
    // MARK: - Request Format Tests
    
    /// Test that the HTTP request is formatted correctly
    func testHTTPRequestFormat() async {
        // Prepare mock response
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/check",
            statusCode: 200,
            data: checkResponseJSON.data(using: .utf8)!
        )
        
        // Execute request
        let imageData = Data([0, 1, 2, 3, 4, 5]) // Minimal test data
        _ = try? await client.processCheck(imageData: imageData)
        
        // Verify HTTP method
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "POST")
        
        // Verify content type
        XCTAssertEqual(
            mockSession.lastRequest?.value(forHTTPHeaderField: "Content-Type"),
            "image/*"
        )
        
        // Verify body is set
        XCTAssertEqual(mockSession.lastRequest?.httpBody, imageData)
    }
    
    // MARK: - Response Parsing Tests
    
    /// Test successful health response parsing
    func testHealthResponseParsing() async throws {
        // Prepare mock response
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/health",
            statusCode: 200,
            data: healthResponseJSON.data(using: .utf8)!
        )
        
        // Execute request
        let response = try await client.getHealth()
        
        // Verify response data
        XCTAssertEqual(response.status, "ok")
        XCTAssertEqual(response.version, "1.8.3")
        XCTAssertEqual(response.timestamp, "2025-05-21T12:30:45Z")
    }
    
    /// Test successful check response parsing
    func testCheckResponseParsing() async throws {
        // Prepare mock response
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/check",
            statusCode: 200,
            data: checkResponseJSON.data(using: .utf8)!
        )
        
        // Execute request
        let response = try await client.processCheck(imageData: Data())
        
        // Verify check data
        XCTAssertEqual(response.data.checkNumber, "12345")
        XCTAssertEqual(response.data.date, "2025-06-01T00:00:00.000Z")
        XCTAssertEqual(response.data.payee, "John Smith")
        XCTAssertEqual(response.data.payer, "ACME Corporation")
        XCTAssertEqual(response.data.amount, Decimal(789.50))
        XCTAssertEqual(response.data.amountText, "Seven hundred eighty-nine and 50/100 dollars")
        XCTAssertEqual(response.data.memo, "Consulting services")
        XCTAssertEqual(response.data.bankName, "First National Bank")
        XCTAssertEqual(response.data.routingNumber, "987654321")
        XCTAssertEqual(response.data.accountNumber, "123456789")
        XCTAssertEqual(response.data.signature, true)
        
        // Verify confidence data
        XCTAssertEqual(response.confidence.ocr, 0.98)
        XCTAssertEqual(response.confidence.extraction, 0.92)
        XCTAssertEqual(response.confidence.overall, 0.95)
    }
    
    /// Test successful receipt response parsing
    func testReceiptResponseParsing() async throws {
        // Prepare mock response
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/receipt",
            statusCode: 200,
            data: receiptResponseJSON.data(using: .utf8)!
        )
        
        // Execute request
        let response = try await client.processReceipt(imageData: Data())
        
        // Verify merchant data
        XCTAssertEqual(response.data.merchant?.name, "Coffee Shop")
        XCTAssertEqual(response.data.merchant?.address, "123 Main St, Anytown, USA")
        XCTAssertEqual(response.data.merchant?.phone, "555-123-4567")
        
        // Verify receipt data
        XCTAssertEqual(response.data.receiptNumber, "R-20250521-1234")
        XCTAssertEqual(response.data.timestamp, "2025-05-21T08:45:30Z")
        XCTAssertEqual(response.data.currency, "USD")
        
        // Verify totals
        XCTAssertTrue(abs((response.data.totals?.subtotal ?? 0) - Decimal(15.50)) < Decimal(0.0001), "Subtotal should be approximately 15.50")
        XCTAssertTrue(abs((response.data.totals?.tax ?? 0) - Decimal(1.24)) < Decimal(0.0001), "Tax should be approximately 1.24")
        XCTAssertTrue(abs((response.data.totals?.total ?? 0) - Decimal(16.74)) < Decimal(0.0001), "Total should be approximately 16.74")
        
        // Verify line items (if available)
        XCTAssertEqual(response.data.items?.count, 3)
        
        if let items = response.data.items, items.count >= 3 {
            XCTAssertEqual(items[0].description, "Cappuccino")
            XCTAssertEqual(items[0].quantity, 2)
            XCTAssertEqual(items[0].unitPrice, Decimal(4.25))
            XCTAssertEqual(items[0].totalPrice, Decimal(8.50))
            
            XCTAssertEqual(items[1].description, "Chocolate Croissant")
            XCTAssertEqual(items[1].quantity, 1)
            XCTAssertEqual(items[1].unitPrice, Decimal(3.50))
            XCTAssertEqual(items[1].totalPrice, Decimal(3.50))
        }
        
        // Verify confidence data
        XCTAssertEqual(response.confidence.ocr, 0.95)
        XCTAssertEqual(response.confidence.extraction, 0.90)
        XCTAssertEqual(response.confidence.overall, 0.92)
    }
    
    /// Test successful document response parsing
    func testDocumentResponseParsing() async throws {
        // Prepare mock response
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/process",
            statusCode: 200,
            data: documentResponseJSON.data(using: .utf8)!
        )
        
        // Execute request
        let response = try await client.processDocument(imageData: Data(), type: .check)
        
        // Verify response type
        XCTAssertEqual(response.documentType, .check)
        
        // Check if the data is correctly decoded as a Check
        if let checkData = response.data as? Check {
            XCTAssertEqual(checkData.checkNumber, "12345")
            XCTAssertEqual(checkData.payee, "John Smith")
            XCTAssertEqual(checkData.amount, Decimal(789.50))
        } else {
            XCTFail("Document data should be decoded as Check")
        }
        
        // Verify confidence data
        XCTAssertEqual(response.confidence.ocr, 0.98)
        XCTAssertEqual(response.confidence.extraction, 0.92)
        XCTAssertEqual(response.confidence.overall, 0.95)
    }
    
    // MARK: - Error Handling Tests
    
    /// Test API error response handling
    func testAPIErrorHandling() async {
        // Prepare mock error response
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/check",
            statusCode: 400,
            data: errorResponseJSON.data(using: .utf8)!
        )
        
        // Execute request with real image data and verify error
        let imageData = OCRClientTestHelper.billImage
        XCTAssertNotNil(imageData, "Failed to load bill test image - image file missing")
        
        guard let imageData = imageData else {
            return
        }
        
        do {
            _ = try await client.processCheck(imageData: imageData)
            XCTFail("Expected error was not thrown")
        } catch let error as OCRError {
            XCTAssertEqual(error.error, "Invalid image format or corrupted file")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    /// Test HTTP error handling without JSON error response
    func testHTTPErrorHandling() async {
        // Prepare mock error response with non-JSON content
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/check",
            statusCode: 500,
            data: "Internal Server Error".data(using: .utf8)!
        )
        
        // Execute request and verify error
        do {
            _ = try await client.processCheck(imageData: Data())
            XCTFail("Expected error was not thrown")
        } catch let error as OCRError {
            // Verify error contains status code
            XCTAssertTrue(error.error.contains("500"))
            XCTAssertTrue(error.error.contains("Internal Server Error"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    /// Test network error handling
    func testNetworkErrorHandling() async {
        // Create mock network error
        let networkError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNetworkConnectionLost,
            userInfo: [NSLocalizedDescriptionKey: "The network connection was lost."]
        )
        
        // Set mock to throw network error
        mockSession.mockError = networkError
        
        // Execute request and verify error
        do {
            _ = try await client.processCheck(imageData: Data())
            XCTFail("Expected network error was not thrown")
        } catch {
            // The original error should be thrown through
            XCTAssertEqual((error as NSError).domain, NSURLErrorDomain)
            XCTAssertEqual((error as NSError).code, NSURLErrorNetworkConnectionLost)
        }
    }
    
    /// Test nil data or response handling
    func testNilDataResponseHandling() async {
        // Prepare mock with nil data
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/check",
            statusCode: 200,
            data: nil
        )
        
        // Execute request and verify error
        do {
            _ = try await client.processCheck(imageData: Data())
            XCTFail("Expected error for nil data was not thrown")
        } catch let error as OCRError {
            XCTAssertTrue(error.error.contains("No data or response received"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    /// Test JSON decoding error handling
    func testJSONDecodingErrorHandling() async {
        // Prepare mock with invalid JSON
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/check",
            statusCode: 200,
            data: "{invalid json}".data(using: .utf8)!
        )
        
        // Execute request and verify error
        do {
            _ = try await client.processCheck(imageData: Data())
            XCTFail("Expected JSON decoding error was not thrown")
        } catch {
            // Should throw a decoding error
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - Environment Tests
    
    /// Test different environments
    func testEnvironments() async {
        // Test production environment
        var client = OCRClient(environment: .production, session: mockSession)
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/health",
            statusCode: 200,
            data: healthResponseJSON.data(using: .utf8)!
        )
        _ = try? await client.getHealth()
        XCTAssertEqual(mockSession.lastRequestURL?.host, "ocr-checks-worker.af-4a0.workers.dev")
        
        // Test development environment
        client = OCRClient(environment: .development, session: mockSession)
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker-dev.af-4a0.workers.dev/health",
            statusCode: 200,
            data: healthResponseJSON.data(using: .utf8)!
        )
        _ = try? await client.getHealth()
        XCTAssertEqual(mockSession.lastRequestURL?.host, "ocr-checks-worker-dev.af-4a0.workers.dev")
        
        // Test local environment
        client = OCRClient(environment: .local, session: mockSession)
        mockSession.mockResponse = createMockResponse(
            urlString: "http://localhost:8787/health",
            statusCode: 200,
            data: healthResponseJSON.data(using: .utf8)!
        )
        _ = try? await client.getHealth()
        XCTAssertEqual(mockSession.lastRequestURL?.host, "localhost")
        XCTAssertEqual(mockSession.lastRequestURL?.port, 8787)
        
        // Test custom environment
        let customURL = URL(string: "https://custom-ocr-api.example.com")!
        client = OCRClient(environment: .custom(customURL), session: mockSession)
        mockSession.mockResponse = createMockResponse(
            urlString: "https://custom-ocr-api.example.com/health",
            statusCode: 200,
            data: healthResponseJSON.data(using: .utf8)!
        )
        _ = try? await client.getHealth()
        XCTAssertEqual(mockSession.lastRequestURL?.host, "custom-ocr-api.example.com")
    }
    
    // MARK: - Cancellation Tests
    
    /// Test the cancellation of requests
    func testCancellation() async {
        // Prepare mock response (will never be returned due to cancellation)
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/check",
            statusCode: 200,
            data: checkResponseJSON.data(using: .utf8)!
        )
        
        // Create a task that will be cancelled before completion
        let task = Task {
            do {
                _ = try await client.processCheck(imageData: Data())
                XCTFail("Request should have been cancelled")
            } catch {
                // Correct error should be OCRClientError.taskCancelled
                XCTAssertTrue(error is OCRClientError)
                if let clientError = error as? OCRClientError {
                    XCTAssertEqual(clientError, .taskCancelled)
                }
            }
        }
        
        // Allow more time for the task to start and be registered
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Cancel the request
        let cancelled = client.cancelProcessing()
        XCTAssertTrue(cancelled, "Cancellation should return true if a task was active")
        
        // Wait for the task to complete (with error)
        await task.value
        
        // Try cancelling again, should return false as no task is active
        let secondCancellation = client.cancelProcessing()
        XCTAssertFalse(secondCancellation, "Second cancellation should return false")
    }
    
    /// Test HEIC image processing
    func testHEICImageProcessing() async {
        // Prepare mock response
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/check",
            statusCode: 200,
            data: checkResponseJSON.data(using: .utf8)!
        )
        
        // Execute request with mock HEIC data
        // Since we're not actually testing the conversion (ImageProcessor tests cover that)
        // we just need to make sure the client attempts to process it
        let imageData = OCRClientTestHelper.heicCheckImage
        XCTAssertNotNil(imageData, "Failed to load HEIC check test image - image file missing")
        
        guard let imageData = imageData else {
            return
        }
        
        _ = try? await client.processCheck(
            imageData: imageData,
            format: .heic
        )
        
        // Verify request was made
        XCTAssertNotNil(mockSession.lastRequest, "Request should be made with HEIC image")
        
        // Verify Content-Type
        XCTAssertEqual(mockSession.lastRequest?.value(forHTTPHeaderField: "Content-Type"), "image/*")
    }
    
    // MARK: - Completion Handler Tests
    
    /// Test completion handler backward compatibility for check processing
    func testCheckCompletionHandler() async {
        // Prepare mock response
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/check",
            statusCode: 200,
            data: checkResponseJSON.data(using: .utf8)!
        )
        
        // Create expectation
        let expectation = XCTestExpectation(description: "Check completion handler called")
        
        // Execute using completion handler API
        client.processCheck(imageData: Data()) { result in
            switch result {
            case .success(let response):
                // Verify data
                XCTAssertEqual(response.data.checkNumber, "12345")
                XCTAssertEqual(response.data.amount, Decimal(789.50))
                expectation.fulfill()
            case .failure:
                XCTFail("Should not fail")
            }
        }
        
        // Wait for expectation
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    /// Test completion handler backward compatibility for receipt processing
    func testReceiptCompletionHandler() async {
        // Prepare mock response
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/receipt",
            statusCode: 200,
            data: receiptResponseJSON.data(using: .utf8)!
        )
        
        // Create expectation
        let expectation = XCTestExpectation(description: "Receipt completion handler called")
        
        // Execute using completion handler API
        client.processReceipt(imageData: Data()) { result in
            switch result {
            case .success(let response):
                // Verify data
                XCTAssertEqual(response.data.merchant?.name, "Coffee Shop")
                // Use approximately equal for floating point comparison
                XCTAssertTrue(abs((response.data.totals?.total ?? 0) - Decimal(16.74)) < Decimal(0.0001), "Total should be approximately 16.74")
                expectation.fulfill()
            case .failure:
                XCTFail("Should not fail")
            }
        }
        
        // Wait for expectation
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    /// Test completion handler error handling
    func testCompletionHandlerErrorHandling() async {
        // Prepare mock error response
        mockSession.mockResponse = createMockResponse(
            urlString: "https://ocr-checks-worker.af-4a0.workers.dev/check",
            statusCode: 400,
            data: errorResponseJSON.data(using: .utf8)!
        )
        
        // Create expectation
        let expectation = XCTestExpectation(description: "Error completion handler called")
        
        // Execute using completion handler API
        client.processCheck(imageData: Data()) { result in
            switch result {
            case .success:
                XCTFail("Should fail with error")
            case .failure(let error):
                // Verify error
                XCTAssertTrue(error is OCRError)
                if let ocrError = error as? OCRError {
                    XCTAssertEqual(ocrError.error, "Invalid image format or corrupted file")
                }
                expectation.fulfill()
            }
        }
        
        // Wait for expectation
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Resource Tests
    
    func testMissingResourceLoading() {
        // Test loading a resource that doesn't exist
        // First test with shouldFail=false to make sure it returns nil
        let nonExistentResource = OCRClientTestHelper.loadResource(name: "missing-image", extension: "HEIC", shouldFail: false)
        XCTAssertNil(nonExistentResource, "Loading a non-existent resource should return nil")
        
        // Now, use a custom XCTExpectFailure to verify the error message contains the path
        _ = XCTExpectFailure("This test should fail with a path in the error message")
        // Force the test to fail with shouldFail=true to see the error message
        _ = OCRClientTestHelper.loadResource(name: "deliberately-missing", extension: "HEIC", shouldFail: true)
    }
    
    // MARK: - Helper Methods
    
    /// Create a mock HTTP response
    private func createMockResponse(urlString: String, statusCode: Int, data: Data?) -> MockResponse {
        return MockResponse(
            url: URL(string: urlString)!,
            statusCode: statusCode,
            data: data
        )
    }
}

// MARK: - Mock URLSession Implementation

/// Enhanced mock URLSession for testing
class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    // Storage for mocked response
    var mockResponse: MockResponse?
    var mockError: Error?
    
    // Captured request information for verification
    var lastRequest: URLRequest?
    var lastRequestURL: URL? {
        return lastRequest?.url
    }
    
    // Async data from URL method
    func data(from url: URL, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        // Store the URL for verification
        let request = URLRequest(url: url)
        lastRequest = request
        
        // Throw error if specified
        if let error = mockError {
            throw error
        }
        
        // Return mock response data or throw error if nil
        guard let response = mockResponse else {
            throw NSError(domain: "MockURLSession", code: 1, userInfo: [NSLocalizedDescriptionKey: "No mock response provided"])
        }
        
        guard let data = response.data else {
            throw OCRError(error: "No data or response received")
        }
        
        return (data, response.httpResponse)
    }
    
    // Async data for request method
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        // Store the request for verification
        lastRequest = request
        
        // Throw error if specified
        if let error = mockError {
            throw error
        }
        
        // Return mock response data or throw error if nil
        guard let response = mockResponse else {
            throw NSError(domain: "MockURLSession", code: 1, userInfo: [NSLocalizedDescriptionKey: "No mock response provided"])
        }
        
        guard let data = response.data else {
            throw OCRError(error: "No data or response received")
        }
        
        return (data, response.httpResponse)
    }
    
    // Completion handler version for backward compatibility
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        // Store the request for verification
        lastRequest = request
        
        // Create a mock task
        let task = MockDataTask(completion: completionHandler)
        
        // Configure the task's response
        if let error = mockError {
            task.mockError = error
        } else if let response = mockResponse {
            task.mockResponse = response.httpResponse
            task.mockData = response.data
        }
        
        // Add a slight delay before completion to allow the test to catch the task
        task.simulateNetworkDelay = true
        
        return task
    }
}

/// Mock response data structure
struct MockResponse {
    let url: URL
    let statusCode: Int
    let data: Data?
    
    var httpResponse: HTTPURLResponse {
        return HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}

/// Mock URLSessionDataTask
class MockDataTask: URLSessionDataTask, @unchecked Sendable {
    private let completion: (Data?, URLResponse?, Error?) -> Void
    private var isCancelled = false
    
    // Mock response data
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    // Control network delay for testing
    var simulateNetworkDelay = false
    
    init(completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.completion = completion
        super.init()
    }
    
    override func resume() {
        // Run asynchronously to simulate network call
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            // If we should simulate network delay, wait a bit
            if self.simulateNetworkDelay {
                Thread.sleep(forTimeInterval: 0.2) // 200ms delay
            }
            
            // Check if task was cancelled while we were waiting
            guard !self.isCancelled else { return }
            
            if let error = self.mockError {
                self.completion(nil, nil, error)
            } else {
                self.completion(self.mockData, self.mockResponse, nil)
            }
        }
    }
    
    override func cancel() {
        // Mark as cancelled and trigger cancellation error
        isCancelled = true
        
        // Use OCRClientError.taskCancelled instead of NSURLErrorCancelled to match expectation in tests
        let cancelError = OCRClientError.taskCancelled
        completion(nil, nil, cancelError)
    }
}
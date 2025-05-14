import XCTest
@testable import NolockOCR

class OCRClientAsyncTests: XCTestCase {
    static var allTests = [
        ("testGetHealthAsync", testGetHealthAsync),
        ("testProcessCheckAsync", testProcessCheckAsync),
        ("testCompletionHandlerCompatibility", testCompletionHandlerCompatibility),
        ("testCancellation", testCancellation)
    ]
    // Mock success response to simulate URLSession responses
    private func mockSuccessResponse<T: Encodable>(data: T) -> (Data, URLResponse) {
        let jsonData = try! JSONEncoder().encode(data)
        let response = HTTPURLResponse(
            url: URL(string: "https://ocr-checks-worker.af-4a0.workers.dev")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (jsonData, response)
    }
    
    // Test the getHealth async method
    func testGetHealthAsync() async throws {
        // Create a mock URLSession
        let mockSession = URLSessionMock()
        let client = OCRClient(environment: .production, session: mockSession)
        
        // Mock response
        let healthResponse = HealthResponse(
            status: "ok",
            timestamp: "2025-05-24T10:30:00Z",
            version: "1.18.0"
        )
        mockSession.nextResponse = mockSuccessResponse(data: healthResponse)
        
        // Test the async method
        let result = try await client.getHealth()
        
        // Verify results
        XCTAssertEqual(result.status, "ok")
        XCTAssertEqual(result.version, "1.18.0")
        XCTAssertEqual(result.timestamp, "2025-05-24T10:30:00Z")
    }
    
    // Test the processCheck async method
    func testProcessCheckAsync() async throws {
        // Create a mock URLSession
        let mockSession = URLSessionMock()
        let client = OCRClient(environment: .production, session: mockSession)
        
        // Mock response
        let checkData = Check(
            checkNumber: "1234",
            date: "2025-05-01",
            payee: "John Doe",
            payer: "ACME Corp",
            amount: "250.00",
            amountText: "Two hundred fifty dollars",
            memo: "Invoice #12345",
            bankName: "First Bank",
            routingNumber: "123456789",
            accountNumber: "987654321",
            checkType: nil,
            accountType: nil,
            signature: true,
            signatureText: nil,
            fractionalCode: nil,
            micrLine: nil,
            metadata: nil,
            confidence: 0.95
        )
        
        let confidence = Confidence(ocr: 0.98, extraction: 0.95, overall: 0.92)
        let checkResponse = CheckResponse(data: checkData, confidence: confidence)
        
        mockSession.nextResponse = mockSuccessResponse(data: checkResponse)
        
        // Test the async method with some image data
        let imageData = Data([0, 1, 2, 3, 4]) // Dummy image data
        let result = try await client.processCheck(imageData: imageData)
        
        // Verify results
        XCTAssertEqual(result.data.checkNumber, "1234")
        XCTAssertEqual(result.data.payee, "John Doe")
        XCTAssertEqual(result.data.amount, "250.00")
        XCTAssertEqual(result.confidence.overall, 0.92)
    }
    
    // Test the backward compatibility with completion handlers
    func testCompletionHandlerCompatibility() async throws {
        // Create a mock URLSession
        let mockSession = URLSessionMock()
        let client = OCRClient(environment: .production, session: mockSession)
        
        // Mock response
        let healthResponse = HealthResponse(
            status: "ok",
            timestamp: "2025-05-24T10:30:00Z",
            version: "1.18.0"
        )
        mockSession.nextResponse = mockSuccessResponse(data: healthResponse)
        
        // Test using completion handler
        let expectation = XCTestExpectation(description: "Completion handler called")
        
        client.getHealth { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.status, "ok")
                XCTAssertEqual(response.version, "1.18.0")
                expectation.fulfill()
            case .failure:
                XCTFail("Should not fail")
            }
        }
        
        // Wait for the expectation to be fulfilled
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // Test the cancellation functionality
    func testCancellation() async throws {
        // Create a mock URLSession with a longer delay
        let mockSession = URLSessionMock()
        mockSession.simulateDelay = 1.0
        let client = OCRClient(environment: .production, session: mockSession)
        
        // Mock response
        let checkData = Check(
            checkNumber: "1234",
            date: "2025-05-01",
            payee: "John Doe",
            payer: "ACME Corp",
            amount: "250.00",
            amountText: "Two hundred fifty dollars",
            memo: "Invoice #12345",
            bankName: "First Bank",
            routingNumber: "123456789",
            accountNumber: "987654321",
            checkType: nil,
            accountType: nil,
            signature: true,
            signatureText: nil,
            fractionalCode: nil,
            micrLine: nil,
            metadata: nil,
            confidence: 0.95
        )
        
        let confidence = Confidence(ocr: 0.98, extraction: 0.95, overall: 0.92)
        let checkResponse = CheckResponse(data: checkData, confidence: confidence)
        mockSession.nextResponse = mockSuccessResponse(data: checkResponse)
        
        // Create a task that will be cancelled
        Task {
            do {
                // This should be cancelled before it completes
                let _ = try await client.processCheck(imageData: Data())
                XCTFail("Request should have been cancelled")
            } catch {
                // We expect an error here due to cancellation
                // Check if it's the expected cancellation error
                if let clientError = error as? OCRClientError {
                    XCTAssertEqual(clientError, OCRClientError.taskCancelled)
                } else if let urlError = error as? URLError, urlError.code == .cancelled {
                    // NSURLErrorCancelled is also acceptable
                    XCTAssertEqual(urlError.code, .cancelled)
                } else {
                    XCTFail("Unexpected error type: \(error)")
                }
            }
        }
        
        // Wait a moment to ensure the task has started
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        // Now cancel the task
        let result = client.cancelProcessing()
        XCTAssertTrue(result, "Cancellation should return true if a task was cancelled")
        
        // Try cancelling again, should return false as no task is active
        let secondResult = client.cancelProcessing()
        XCTAssertFalse(secondResult, "Second cancellation should return false as no task is active")
    }
}

// Simple mock URLSession for testing
class URLSessionDataTaskMock: URLSessionDataTask {
    private let completionHandler: (Data?, URLResponse?, Error?) -> Void
    private let mockData: Data?
    private let mockResponse: URLResponse?
    private let mockError: Error?
    private var isCancelled = false
    private let delay: TimeInterval
    
    init(mockData: Data?, mockResponse: URLResponse?, mockError: Error?, 
         delay: TimeInterval = 0.1,
         completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        self.mockData = mockData
        self.mockResponse = mockResponse
        self.mockError = mockError
        self.delay = delay
        self.completionHandler = completionHandler
        super.init()
    }
    
    override func resume() {
        // Simulate async network call by using configurable delay
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            
            if self.isCancelled {
                self.completionHandler(nil, nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
            } else {
                self.completionHandler(self.mockData, self.mockResponse, self.mockError)
            }
        }
    }
    
    override func cancel() {
        isCancelled = true
    }
}

class URLSessionMock: URLSessionProtocol {
    var nextResponse: (Data, URLResponse)!
    var nextError: Error?
    var simulateDelay: TimeInterval = 0.1
    var lastRequest: URLRequest?
    
    func data(from url: URL, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse) {
        if let error = nextError {
            throw error
        }
        return nextResponse
    }
    
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse) {
        lastRequest = request
        if let error = nextError {
            throw error
        }
        return nextResponse
    }
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        lastRequest = request
        return URLSessionDataTaskMock(
            mockData: nextResponse?.0,
            mockResponse: nextResponse?.1,
            mockError: nextError,
            delay: simulateDelay,
            completionHandler: completionHandler
        )
    }
}
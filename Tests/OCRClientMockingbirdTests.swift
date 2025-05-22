import XCTest
import Foundation
@testable import NolockOCR
import Mockingbird

// IMPORTANT: This test file requires generated mocks before it can be run.
// Run ./generate-mocks.sh first to generate the necessary mock types.

/// Tests for OCRClient using Mockingbird for mocking
class OCRClientMockingbirdTests: XCTestCase {
    
    // MARK: - Properties
    
    // For now, use our custom mock implementations instead of the generated mocks
    var mockSession: MockURLSession!
    var mockDataTask: MockURLSessionDataTask!
    var client: OCRClient!
    
    // Custom mock implementations
    class MockURLSession: URLSessionProtocol {
        var dataForRequestCalled = false
        var dataTaskCalled = false
        var lastRequest: URLRequest?
        var responseToReturn: (Data, URLResponse)?
        var errorToThrow: Error?
        var mockDataTask: MockURLSessionDataTask!
        
        func data(from url: URL, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
            dataForRequestCalled = true
            if let error = errorToThrow {
                throw error
            }
            if let response = responseToReturn {
                return response
            }
            throw NSError(domain: "MockURLSession", code: 1, userInfo: [NSLocalizedDescriptionKey: "No response configured"])
        }
        
        func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
            dataForRequestCalled = true
            lastRequest = request
            if let error = errorToThrow {
                throw error
            }
            if let response = responseToReturn {
                return response
            }
            throw NSError(domain: "MockURLSession", code: 1, userInfo: [NSLocalizedDescriptionKey: "No response configured"])
        }
        
        func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            dataTaskCalled = true
            lastRequest = request
            
            if mockDataTask == nil {
                mockDataTask = MockURLSessionDataTask()
            }
            
            mockDataTask.completionHandler = completionHandler
            return mockDataTask
        }
    }
    
    class MockURLSessionDataTask: URLSessionDataTask {
        var resumeCalled = false
        var cancelCalled = false
        var completionHandler: ((Data?, URLResponse?, Error?) -> Void)?
        
        override func resume() {
            resumeCalled = true
            // Call completion handler with configured response
            completionHandler?(nil, nil, nil)
        }
        
        override func cancel() {
            cancelCalled = true
            completionHandler?(nil, nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
        }
    }
    
    // MARK: - Test Data
    
    // Mock test image data
    lazy var testImageData = Data(repeating: 0, count: 1024)
    
    // Sample successful response JSON
    static let successResponseJSON = """
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
    
    // Sample error response JSON
    static let errorResponseJSON = """
    {
        "error": "Invalid image format or corrupted image data"
    }
    """
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        
        // Initialize our custom mocks instead of using Mockingbird's mock() function
        mockSession = MockURLSession()
        mockDataTask = MockURLSessionDataTask()
        mockSession.mockDataTask = mockDataTask
        
        // Create the client with the mock session
        client = OCRClient(environment: .production, session: mockSession)
    }
    
    override func tearDown() {
        mockSession = nil
        mockDataTask = nil
        client = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Creates a mock HTTP response for testing
    private func createMockResponse(path: String, statusCode: Int = 200) -> HTTPURLResponse {
        return HTTPURLResponse(
            url: URL(string: "https://ocr-checks-worker.af-4a0.workers.dev\(path)")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
    }
    
    // MARK: - Tests
    
    /// Test successful check processing with async/await
    func testProcessCheckAsync() async throws {
        // ARRANGE
        // Set up response data
        let responseData = Self.successResponseJSON.data(using: .utf8)!
        let successResponse = createMockResponse(path: "/check")
        
        // Set up mock session behavior
        mockSession.responseToReturn = (responseData, successResponse)
        
        // ACT
        // Call the method under test
        let result = try await client.processCheck(imageData: testImageData)
        
        // ASSERT
        // Verify the session was called
        XCTAssertTrue(mockSession.dataForRequestCalled)
        
        // Verify the request URL contains the check endpoint
        XCTAssertNotNil(mockSession.lastRequest)
        XCTAssertTrue(mockSession.lastRequest?.url?.absoluteString.contains("/check") ?? false)
        
        // Verify the result contains expected data
        XCTAssertEqual(result.data.checkNumber, "12345")
        XCTAssertEqual(result.data.payee, "John Smith")
        XCTAssertEqual(result.data.amount, 123.45)
        XCTAssertEqual(result.confidence.overall, 0.95)
    }
    
    /// Test error handling in check processing
    func testErrorHandling() async {
        // ARRANGE
        // Create error response
        let errorData = Self.errorResponseJSON.data(using: .utf8)!
        let errorResponse = createMockResponse(path: "/check", statusCode: 400)
        
        // Set up mock to return an error response
        mockSession.responseToReturn = (errorData, errorResponse)
        
        // ACT & ASSERT
        do {
            _ = try await client.processCheck(imageData: testImageData)
            XCTFail("Expected an error to be thrown")
        } catch let error as OCRError {
            // Verify we got the expected error
            XCTAssertEqual(error.error, "Invalid image format or corrupted image data")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        
        // Verify the session was called
        XCTAssertTrue(mockSession.dataForRequestCalled)
    }
    
    /// Test cancellation handling
    func testCancellation() async {
        // ARRANGE
        // Set up mock session to throw a cancellation error
        mockSession.errorToThrow = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)
        
        // ACT & ASSERT
        do {
            _ = try await client.processCheck(imageData: testImageData)
            XCTFail("Expected an error to be thrown")
        } catch let error as NSError {
            // Verify we got a cancellation error
            XCTAssertEqual(error.domain, NSURLErrorDomain)
            XCTAssertEqual(error.code, NSURLErrorCancelled)
        }
        
        // Verify the session was called
        XCTAssertTrue(mockSession.dataForRequestCalled)
    }
    
    /// Test the completion handler version of processCheck
    func testCompletionHandlerCompatibility() {
        // ARRANGE
        // Set up response data
        let responseData = Self.successResponseJSON.data(using: .utf8)!
        let successResponse = createMockResponse(path: "/check")
        
        // Configure mock data task to call completion handler with our data
        mockDataTask.completionHandler = nil // Clear from previous tests
        
        // Configure our session to set this data when dataTask is called
        mockSession.mockDataTask = mockDataTask
        
        // Set up expectation
        let expectation = XCTestExpectation(description: "Completion handler called")
        
        // ACT
        client.processCheck(imageData: testImageData) { result in
            // Call our expectation manually since our mock doesn't automatically call it
            expectation.fulfill()
            
            // ASSERT
            switch result {
            case .success(let response):
                XCTAssertEqual(response.data.checkNumber, "12345")
                XCTAssertEqual(response.data.payee, "John Smith")
                XCTAssertEqual(response.data.amount, 123.45)
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
        }
        
        // Manually call the completion handler with our mock data
        // This is needed because our mock resume() doesn't know about the specific data we want to return
        if let completionHandler = mockDataTask.completionHandler {
            completionHandler(responseData, successResponse, nil)
        }
        
        // Wait for the expectation
        wait(for: [expectation], timeout: 1.0)
        
        // Verify the session was called to create a data task
        XCTAssertTrue(mockSession.dataTaskCalled)
        
        // Verify the task was resumed
        XCTAssertTrue(mockDataTask.resumeCalled)
    }
    
    /// Test cancelProcessing functionality
    func testCancelProcessing() {
        // ARRANGE
        // Configure mock data task
        mockDataTask.completionHandler = nil // Clear from previous tests
        
        // Set up expectation
        let expectation = XCTestExpectation(description: "Completion handler called")
        
        // ACT - Start a request
        client.processCheck(imageData: testImageData) { _ in
            // This should not be called because we'll cancel before our manual call to the completion handler
            XCTFail("Completion handler should not be called after cancellation")
        }
        
        // Verify the data task has been created
        XCTAssertTrue(mockSession.dataTaskCalled)
        XCTAssertTrue(mockDataTask.resumeCalled)
        
        // Cancel the request
        let result = client.cancelProcessing()
        
        // Wait a moment to ensure cancel has time to process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // ASSERT
        // Wait for the expectation
        wait(for: [expectation], timeout: 1.0)
        
        // Verify cancellation was successful
        XCTAssertTrue(result, "Cancellation should return true")
        XCTAssertTrue(mockDataTask.cancelCalled)
    }
}
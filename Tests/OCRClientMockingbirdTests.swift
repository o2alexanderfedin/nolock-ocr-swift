import XCTest
import Foundation
@testable import NolockOCR
import Mockingbird

/// Tests for OCRClient using Mockingbird for mocking
class OCRClientMockingbirdTests: XCTestCase {
    
    // MARK: - Properties
    
    var mockSession: URLSessionProtocolMock!
    var mockDataTask: URLSessionDataTaskMock!
    var client: OCRClient!
    
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
        
        // Initialize mocks
        mockSession = mock(URLSessionProtocol.self)
        mockDataTask = mock(URLSessionDataTask.self)
        
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
        given(mockSession.data(for: any(), delegate: any()))
            .willReturn((responseData, successResponse))
        
        // ACT
        // Call the method under test
        let result = try await client.processCheck(imageData: testImageData)
        
        // ASSERT
        // Verify the session was called with a request to the check endpoint
        verify(mockSession.data(for: where { request in
            guard let url = request.url else { return false }
            return url.absoluteString.contains("/check")
        }, delegate: any())).wasCalled()
        
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
        given(mockSession.data(for: any(), delegate: any()))
            .willReturn((errorData, errorResponse))
        
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
        verify(mockSession.data(for: any(), delegate: any())).wasCalled()
    }
    
    /// Test cancellation handling
    func testCancellation() async {
        // ARRANGE
        // Set up mock session to throw a cancellation error
        given(mockSession.data(for: any(), delegate: any()))
            .will { _, _ in
                throw NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)
            }
        
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
        verify(mockSession.data(for: any(), delegate: any())).wasCalled()
    }
    
    /// Test the completion handler version of processCheck
    func testCompletionHandlerCompatibility() {
        // ARRANGE
        // Set up response data
        let responseData = Self.successResponseJSON.data(using: .utf8)!
        let successResponse = createMockResponse(path: "/check")
        
        // Mock dataTask creation and execution
        given(mockSession.dataTask(with: any(), completionHandler: any()))
            .will { request, completionHandler in
                // Call the completion handler with our mock data
                completionHandler(responseData, successResponse, nil)
                return self.mockDataTask
            }
        
        // Make sure the mock task resumes when called
        given(mockDataTask.resume()).willReturn(())
        
        // Set up expectation
        let expectation = XCTestExpectation(description: "Completion handler called")
        
        // ACT
        client.processCheck(imageData: testImageData) { result in
            // ASSERT
            switch result {
            case .success(let response):
                XCTAssertEqual(response.data.checkNumber, "12345")
                XCTAssertEqual(response.data.payee, "John Smith")
                XCTAssertEqual(response.data.amount, 123.45)
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
            expectation.fulfill()
        }
        
        // Wait for the expectation
        wait(for: [expectation], timeout: 1.0)
        
        // Verify the session was called to create a data task
        verify(mockSession.dataTask(with: any(), completionHandler: any())).wasCalled()
        
        // Verify the task was resumed
        verify(mockDataTask.resume()).wasCalled()
    }
    
    /// Test cancelProcessing functionality
    func testCancelProcessing() {
        // ARRANGE
        // Mock dataTask creation
        given(mockSession.dataTask(with: any(), completionHandler: any()))
            .willReturn(mockDataTask)
        
        // Mock task cancellation
        given(mockDataTask.resume()).willReturn(())
        given(mockDataTask.cancel()).willReturn(())
        
        // Set up expectation
        let expectation = XCTestExpectation(description: "Completion handler called")
        
        // ACT - Start a request
        client.processCheck(imageData: testImageData) { _ in
            // This should not be called
            XCTFail("Completion handler should not be called after cancellation")
        }
        
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
        
        // Verify the task was created and resumed
        verify(mockSession.dataTask(with: any(), completionHandler: any())).wasCalled()
        verify(mockDataTask.resume()).wasCalled()
        
        // Verify the task was cancelled
        verify(mockDataTask.cancel()).wasCalled()
    }
}
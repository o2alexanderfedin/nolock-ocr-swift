import Foundation
@testable import NolockOCR

/// Manual mock for URLSessionProtocol
class SharedMockURLSession: URLSessionProtocol {
    // Response configuration
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    // Tracking properties
    var requestsReceived: [URLRequest] = []
    var lastRequestURL: URL?
    var lastRequestMethod: String?
    var asyncRequestCount = 0
    var completionHandlerRequestCount = 0
    
    // Control properties
    var delayResponse: TimeInterval = 0
    var simulateCancellation = false
    
    // Document type-specific responses
    var checkResponseData: Data?
    var receiptResponseData: Data?
    var documentResponseData: Data?
    
    func data(from url: URL, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        asyncRequestCount += 1
        lastRequestURL = url
        
        if simulateCancellation {
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)
        }
        
        if delayResponse > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delayResponse * 1_000_000_000))
        }
        
        if let error = mockError {
            throw error
        }
        
        guard let data = mockData, let response = mockResponse else {
            throw NSError(domain: "MockURLSession", code: 1, userInfo: [NSLocalizedDescriptionKey: "No mock data or response"])
        }
        
        return (data, response)
    }
    
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        asyncRequestCount += 1
        lastRequestURL = request.url
        lastRequestMethod = request.httpMethod
        requestsReceived.append(request)
        
        if simulateCancellation {
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)
        }
        
        if delayResponse > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delayResponse * 1_000_000_000))
        }
        
        if let error = mockError {
            throw error
        }
        
        // Select response data based on URL path
        var responseData = mockData
        if let url = request.url?.path {
            if url.contains("/check") {
                responseData = checkResponseData ?? mockData
            } else if url.contains("/receipt") {
                responseData = receiptResponseData ?? mockData
            } else if url.contains("/process") {
                responseData = documentResponseData ?? mockData
            }
        }
        
        guard let data = responseData, let response = mockResponse else {
            throw NSError(domain: "MockURLSession", code: 1, userInfo: [NSLocalizedDescriptionKey: "No mock data or response"])
        }
        
        return (data, response)
    }
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        completionHandlerRequestCount += 1
        lastRequestURL = request.url
        lastRequestMethod = request.httpMethod
        requestsReceived.append(request)
        
        let mockTask = SharedMockURLSessionDataTask()
        mockTask.completionHandler = completionHandler
        mockTask.mockSession = self
        mockTask.mockRequest = request
        
        // Configure the task with our mock data
        mockTask.mockData = mockData
        mockTask.mockResponse = mockResponse
        mockTask.mockError = mockError
        mockTask.delayResponse = delayResponse
        mockTask.simulateCancellation = simulateCancellation
        
        // Select response data based on URL path
        if let url = request.url?.path {
            if url.contains("/check") {
                mockTask.mockData = checkResponseData ?? mockData
            } else if url.contains("/receipt") {
                mockTask.mockData = receiptResponseData ?? mockData
            } else if url.contains("/process") {
                mockTask.mockData = documentResponseData ?? mockData
            }
        }
        
        return mockTask
    }
    
    // Reset all tracking properties
    func reset() {
        requestsReceived = []
        lastRequestURL = nil
        lastRequestMethod = nil
        asyncRequestCount = 0
        completionHandlerRequestCount = 0
        simulateCancellation = false
        delayResponse = 0
    }
}

/// Mock URLSessionDataTask for testing
class SharedMockURLSessionDataTask: URLSessionDataTask, @unchecked Sendable {
    // Configuration
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var delayResponse: TimeInterval = 0
    var simulateCancellation = false
    
    // Request tracking
    var mockRequest: URLRequest?
    weak var mockSession: SharedMockURLSession?
    var completionHandler: ((Data?, URLResponse?, Error?) -> Void)?
    var isCancelled = false
    var isResumed = false
    
    override func resume() {
        isResumed = true
        
        guard let completionHandler = completionHandler else { return }
        
        // Simulate async execution
        DispatchQueue.global().asyncAfter(deadline: .now() + delayResponse) { [weak self] in
            guard let self = self else { return }
            
            // If cancelled, don't call completion handler with data
            if self.isCancelled || self.simulateCancellation {
                let cancelError = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)
                completionHandler(nil, nil, cancelError)
                return
            }
            
            completionHandler(self.mockData, self.mockResponse, self.mockError)
        }
    }
    
    override func cancel() {
        isCancelled = true
        // In a real implementation, the completion handler would be called with a cancellation error
        if let completionHandler = completionHandler {
            let cancelError = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)
            completionHandler(nil, nil, cancelError)
        }
    }
}
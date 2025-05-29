import Foundation

// Note: Image processing is now handled by ImageProcessor in Core directory

// We now use the types from Models/Common.swift

/// Universal document processing response
public struct DocumentResponse: Codable {
    /// Extracted document data (either Check or Receipt)
    public let data: Codable
    
    /// Type of document processed
    public let documentType: DocumentType
    
    /// Confidence scores for the processing
    public let confidence: Confidence
    
    enum CodingKeys: String, CodingKey {
        case data
        case documentType
        case confidence
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        documentType = try container.decode(DocumentType.self, forKey: .documentType)
        confidence = try container.decode(Confidence.self, forKey: .confidence)
        
        // Decode the data based on documentType
        switch documentType {
        case .check:
            let checkData = try container.decode(Check.self, forKey: .data)
            data = checkData
        case .receipt:
            let receiptData = try container.decode(Receipt.self, forKey: .data)
            data = receiptData
        case .auto:
            // For auto detection, default to receipt for compatibility
            let receiptData = try container.decode(Receipt.self, forKey: .data)
            data = receiptData
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(documentType, forKey: .documentType)
        try container.encode(confidence, forKey: .confidence)
        
        // Encode data based on its actual type
        if let checkData = data as? Check {
            try container.encode(checkData, forKey: .data)
        } else if let receiptData = data as? Receipt {
            try container.encode(receiptData, forKey: .data)
        } else {
            throw EncodingError.invalidValue(data, EncodingError.Context(
                codingPath: [CodingKeys.data],
                debugDescription: "Data must be either Check or Receipt"
            ))
        }
    }
}

/// Health status response from the API
public struct HealthResponse: Codable {
    /// Server status (always "ok")
    public let status: String
    
    /// Current server time
    public let timestamp: String
    
    /// Server version
    public let version: String
}

/// Protocol for using with URLSession mocking
public protocol URLSessionProtocol {
    func data(from url: URL, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)
    
    /// Create a data task that can be started and cancelled
    func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

/// Extend URLSession to conform to the protocol
extension URLSession: URLSessionProtocol {}

// We now use the types from Models/Errors/OCRClientError.swift

/// Main client for the OCR Checks Server API
public class OCRClient {
    private let baseURL: URL
    private let session: URLSessionProtocol
    
    /// Active task that can be cancelled
    private var activeTask: URLSessionDataTask?
    
    /// Cancel token to track task cancellation in async/await API
    private var isCancelled = false
    
    /// URL builder for constructing endpoint URLs
    private let endpointBuilder: EndpointBuilder
    
    /// Image processor for handling image format conversion
    private let imageProcessor: ImageProcessing
    
    // Using ClientEnvironment from Core/ClientEnvironment.swift
    public typealias Environment = ClientEnvironment
    
    /// Initialize a new OCR client with the specified environment
    /// - Parameter environment: The server environment to use
    /// - Parameter session: URLSession for network requests (defaults to shared session)
    public init(environment: Environment = .production, session: URLSessionProtocol = URLSession.shared, imageProcessor: ImageProcessing = ImageProcessor.shared) {
        self.baseURL = environment.url
        self.session = session
        self.endpointBuilder = EndpointBuilder(baseURL: environment.url)
        self.imageProcessor = imageProcessor
        self.activeTask = nil
        self.isCancelled = false
    }
    
    /// Cancel any active processing task
    /// - Returns: True if a task was cancelled, false if no task was active
    @discardableResult
    public func cancelProcessing() -> Bool {
        // Reset cancellation flag
        isCancelled = true
        
        // Cancel active task if one exists
        if let task = activeTask {
            task.cancel()
            activeTask = nil
            return true
        }
        
        return false
    }
    
    // MARK: - Async/Await API Methods
    
    /// Process a check image using async/await
    /// - Parameters:
    ///   - imageData: The image data to process
    ///   - format: Format of the document (default: .image)
    ///   - filename: Optional filename for the document
    /// - Returns: A CheckResponse containing the processed check data
    /// - Throws: An error if the processing fails
    public func processCheck(
        imageData: Data,
        format: DocumentFormat = .image,
        filename: String? = nil
    ) async throws -> CheckResponse {
        let parameters: [String: String?] = [
            "format": format.rawValue,
            "filename": filename
        ]
        
        let url = try endpointBuilder.buildProcessingURL(
            endpoint: .check,
            parameters: parameters
        )
        
        return try await performRequest(url: url, imageData: imageData)
    }
    
    /// Process a receipt image using async/await
    /// - Parameters:
    ///   - imageData: The image data to process
    ///   - format: Format of the document (default: .image)
    ///   - filename: Optional filename for the document
    /// - Returns: A ReceiptResponse containing the processed receipt data
    /// - Throws: An error if the processing fails
    public func processReceipt(
        imageData: Data,
        format: DocumentFormat = .image,
        filename: String? = nil
    ) async throws -> ReceiptResponse {
        let parameters: [String: String?] = [
            "format": format.rawValue,
            "filename": filename
        ]
        
        let url = try endpointBuilder.buildProcessingURL(
            endpoint: .receipt,
            parameters: parameters
        )
        
        return try await performRequest(url: url, imageData: imageData)
    }
    
    /// Process a document as either a check or receipt using async/await
    /// - Parameters:
    ///   - imageData: The image data to process
    ///   - type: Type of document to process
    ///   - format: Format of the document (default: .image)
    ///   - filename: Optional filename for the document
    /// - Returns: A DocumentResponse containing the processed document data
    /// - Throws: An error if the processing fails
    public func processDocument(
        imageData: Data,
        type: DocumentType,
        format: DocumentFormat = .image,
        filename: String? = nil
    ) async throws -> DocumentResponse {
        let parameters: [String: String?] = [
            "format": format.rawValue,
            "filename": filename
        ]
        
        let url = try endpointBuilder.buildProcessingURL(
            endpoint: .document(type: type),
            parameters: parameters
        )
        
        return try await performRequest(url: url, imageData: imageData)
    }
    
    /// Get server health status using async/await
    /// - Returns: A HealthResponse containing the server health information
    /// - Throws: An error if the request fails
    public func getHealth() async throws -> HealthResponse {
        let requestId = UUID().uuidString.prefix(8)
        let startTime = Date()
        
        print("💊 [\(requestId)] Starting health check request")
        
        // Reset cancellation flag at the start of a new request
        isCancelled = false
        print("✅ [\(requestId)] Cancellation flag reset for health check")
        
        let url = try endpointBuilder.buildProcessingURL(endpoint: .health)
        print("🔗 [\(requestId)] Health check URL: \(url.absoluteString)")
        
        let request = URLRequest(url: url)
        print("📤 [\(requestId)] Health check request method: \(request.httpMethod ?? "GET")")
        
        // Check if cancelled before starting the request
        if isCancelled {
            print("❌ [\(requestId)] Health check cancelled before starting")
            throw OCRClientError.taskCancelled
        }
        
        print("🚀 [\(requestId)] Initiating health check network request...")
        let networkStartTime = Date()
        
        return try await withCheckedThrowingContinuation { continuation in
            // Create a task that can be cancelled
            let task = session.dataTask(with: request) { data, response, error in
                let networkTime = Date().timeIntervalSince(networkStartTime)
                let totalTime = Date().timeIntervalSince(startTime)
                
                print("📡 [\(requestId)] Health check response received in \(String(format: "%.3f", networkTime))s")
                print("⏱️ [\(requestId)] Total health check time: \(String(format: "%.3f", totalTime))s")
                
                // Clear the active task reference
                self.activeTask = nil
                
                // Handle cancellation
                if self.isCancelled {
                    print("❌ [\(requestId)] Health check was cancelled during execution")
                    continuation.resume(throwing: OCRClientError.taskCancelled)
                    return
                }
                
                // Handle connection errors
                if let error = error {
                    print("💥 [\(requestId)] Health check network error: \(error.localizedDescription)")
                    if let urlError = error as? URLError {
                        print("🔍 [\(requestId)] URLError code: \(urlError.code.rawValue)")
                    }
                    continuation.resume(throwing: error)
                    return
                }
                
                // Ensure we have valid data and response
                guard let data = data, let response = response else {
                    continuation.resume(throwing: OCRError(error: "No data or response received"))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.resume(throwing: OCRError(error: "Invalid response"))
                    return
                }
                
                // Handle HTTP errors
                guard (200...299).contains(httpResponse.statusCode) else {
                    // Print the response body for debugging
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                    print("HTTP Error \(httpResponse.statusCode): \(responseString)")
                    
                    if let errorResponse = try? JSONDecoder().decode(OCRError.self, from: data) {
                        continuation.resume(throwing: errorResponse)
                    } else {
                        continuation.resume(throwing: OCRError(error: "HTTP Error: \(httpResponse.statusCode) - \(responseString)"))
                    }
                    return
                }
                
                // Print raw response data for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON Health Response: \(jsonString)")
                }
                
                // Process successful response
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(HealthResponse.self, from: data)
                    continuation.resume(returning: result)
                } catch {
                    print("JSON Decoding Error: \(error)")
                    continuation.resume(throwing: error)
                }
            }
            
            // Store the task so it can be cancelled from the outside
            self.activeTask = task
            
            // Start the task
            task.resume()
        }
    }
    
    // MARK: - Backward Compatibility Methods with Completion Handlers
    
    /// Process a check image
    /// - Parameters:
    ///   - imageData: The image data to process
    ///   - format: Format of the document (default: .image)
    ///   - filename: Optional filename for the document
    ///   - completion: Completion handler with result
    public func processCheck(
        imageData: Data,
        format: DocumentFormat = .image,
        filename: String? = nil,
        completion: @escaping (Result<CheckResponse, Error>) -> Void
    ) {
        Task {
            do {
                let response = try await processCheck(imageData: imageData, format: format, filename: filename)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Process a receipt image
    /// - Parameters:
    ///   - imageData: The image data to process
    ///   - format: Format of the document (default: .image)
    ///   - filename: Optional filename for the document
    ///   - completion: Completion handler with result
    public func processReceipt(
        imageData: Data,
        format: DocumentFormat = .image,
        filename: String? = nil,
        completion: @escaping (Result<ReceiptResponse, Error>) -> Void
    ) {
        Task {
            do {
                let response = try await processReceipt(imageData: imageData, format: format, filename: filename)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Process a document as either a check or receipt
    /// - Parameters:
    ///   - imageData: The image data to process
    ///   - type: Type of document to process
    ///   - format: Format of the document (default: .image)
    ///   - filename: Optional filename for the document
    ///   - completion: Completion handler with result
    public func processDocument(
        imageData: Data,
        type: DocumentType,
        format: DocumentFormat = .image,
        filename: String? = nil,
        completion: @escaping (Result<DocumentResponse, Error>) -> Void
    ) {
        Task {
            do {
                let response = try await processDocument(imageData: imageData, type: type, format: format, filename: filename)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Get server health status
    /// - Parameter completion: Completion handler with result
    public func getHealth(completion: @escaping (Result<HealthResponse, Error>) -> Void) {
        Task {
            do {
                let response = try await getHealth()
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Set a custom URLSessionProtocol for testing
    /// This method should only be used in test code
    /// - Parameter session: The URLSessionProtocol to use
    static func useCustomURLSession(_ session: URLSessionProtocol) {
        // Save the session in a way that OCRProcessingService can access
        // This is a simple static property approach for testing
        sharedTestSession = session
    }
    
    /// Shared test session for use in tests
    private static var sharedTestSession: URLSessionProtocol?
    
    /// Get the appropriate session to use (real or mock)
    /// - Returns: The URLSessionProtocol to use
    public static func getSession() -> URLSessionProtocol {
        // Use the custom session if set, otherwise use the shared session
        return sharedTestSession ?? URLSession.shared
    }
    
    /// Get the test session if available
    /// - Returns: The URLSessionProtocol to use for tests, or nil if none is set
    static func getSessionForTest() -> URLSessionProtocol? {
        return sharedTestSession
    }
    
    private func performRequest<T: Decodable>(
        url: URL, 
        imageData: Data
    ) async throws -> T {
        let requestId = UUID().uuidString.prefix(8)
        let startTime = Date()
        
        print("🔄 [\(requestId)] Starting request to: \(url.absoluteString)")
        print("📊 [\(requestId)] Original image size: \(imageData.count) bytes")
        
        // Reset cancellation flag at the start of a new request
        isCancelled = false
        print("✅ [\(requestId)] Cancellation flag reset")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Process the image data - convert HEIC to PNG if needed
        print("🖼️ [\(requestId)] Processing image data...")
        let imageProcessingStart = Date()
        let (processedData, wasConverted) = try processImageDataWithInfo(imageData)
        let imageProcessingTime = Date().timeIntervalSince(imageProcessingStart)
        
        print("📸 [\(requestId)] Image processing complete in \(String(format: "%.3f", imageProcessingTime))s")
        print("🔄 [\(requestId)] Image converted: \(wasConverted ? "YES" : "NO")")
        print("📏 [\(requestId)] Processed image size: \(processedData.count) bytes")
        
        // Use image/* content type for better compatibility with server
        let contentType = "image/*"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = processedData
        
        print("📤 [\(requestId)] HTTP Method: \(request.httpMethod ?? "Unknown")")
        print("📤 [\(requestId)] Content-Type: \(contentType)")
        print("📤 [\(requestId)] Request body size: \(processedData.count) bytes")
        
        // Check if cancelled before starting the request
        if isCancelled {
            print("❌ [\(requestId)] Request cancelled before starting")
            throw OCRClientError.taskCancelled
        }
        
        print("🚀 [\(requestId)] Initiating network request...")
        let networkStartTime = Date()
        
        return try await withCheckedThrowingContinuation { continuation in
            // Create a task that can be cancelled
            let task = session.dataTask(with: request) { data, response, error in
                let networkTime = Date().timeIntervalSince(networkStartTime)
                let totalTime = Date().timeIntervalSince(startTime)
                
                print("📡 [\(requestId)] Network response received in \(String(format: "%.3f", networkTime))s")
                print("⏱️ [\(requestId)] Total request time: \(String(format: "%.3f", totalTime))s")
                
                // Store the task reference so it can be cancelled
                self.activeTask = nil
                
                // Handle cancellation
                if self.isCancelled {
                    print("❌ [\(requestId)] Request was cancelled during execution")
                    continuation.resume(throwing: OCRClientError.taskCancelled)
                    return
                }
                
                // Handle connection errors
                if let error = error {
                    print("💥 [\(requestId)] Network error: \(error.localizedDescription)")
                    if let urlError = error as? URLError {
                        print("🔍 [\(requestId)] URLError code: \(urlError.code.rawValue)")
                        print("🔍 [\(requestId)] URLError domain: \(urlError.errorCode)")
                    }
                    continuation.resume(throwing: error)
                    return
                }
                
                // Ensure we have valid data and response
                guard let data = data, let response = response else {
                    print("❌ [\(requestId)] No data or response received")
                    continuation.resume(throwing: OCRError(error: "No data or response received"))
                    return
                }
                
                print("📦 [\(requestId)] Response data size: \(data.count) bytes")
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ [\(requestId)] Invalid HTTP response type")
                    continuation.resume(throwing: OCRError(error: "Invalid response"))
                    return
                }
                
                print("📊 [\(requestId)] HTTP Status Code: \(httpResponse.statusCode)")
                print("📋 [\(requestId)] Response Headers: \(httpResponse.allHeaderFields)")
                
                // Handle HTTP errors
                guard (200...299).contains(httpResponse.statusCode) else {
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                    print("💥 [\(requestId)] HTTP Error \(httpResponse.statusCode)")
                    print("📄 [\(requestId)] Error response body: \(responseString)")
                    
                    if let errorResponse = try? JSONDecoder().decode(OCRError.self, from: data) {
                        print("🔍 [\(requestId)] Parsed OCR error: \(errorResponse)")
                        continuation.resume(throwing: errorResponse)
                    } else {
                        print("🔍 [\(requestId)] Unable to parse error response as OCRError")
                        continuation.resume(throwing: OCRError(error: "HTTP Error: \(httpResponse.statusCode) - \(responseString)"))
                    }
                    return
                }
                
                // Process successful response
                print("✅ [\(requestId)] HTTP request successful (\(httpResponse.statusCode))")
                
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 [\(requestId)] Raw JSON Response (\(data.count) bytes): \(jsonString.prefix(500))\(jsonString.count > 500 ? "..." : "")")
                } else {
                    print("⚠️ [\(requestId)] Unable to decode response as UTF-8 string")
                }
                
                let decodingStart = Date()
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(T.self, from: data)
                    let decodingTime = Date().timeIntervalSince(decodingStart)
                    let finalTotalTime = Date().timeIntervalSince(startTime)
                    
                    print("🎯 [\(requestId)] JSON decoding successful in \(String(format: "%.3f", decodingTime))s")
                    print("🏁 [\(requestId)] Complete request finished in \(String(format: "%.3f", finalTotalTime))s")
                    continuation.resume(returning: result)
                } catch {
                    let decodingTime = Date().timeIntervalSince(decodingStart)
                    print("💥 [\(requestId)] JSON decoding failed in \(String(format: "%.3f", decodingTime))s")
                    print("🔍 [\(requestId)] Decoding error: \(error)")
                    print("📝 [\(requestId)] Expected type: \(T.self)")
                    continuation.resume(throwing: error)
                }
            }
            
            // Store the task so it can be cancelled from the outside
            self.activeTask = task
            
            // Start the task
            task.resume()
        }
    }
    
    /// Process image data before sending to server
    /// - Converts HEIC images to PNG
    /// - Returns original data for already supported formats
    /// - Returns: Processed image data
    @available(*, deprecated, message: "Use processImageDataWithInfo instead")
    private func processImageData(_ imageData: Data) throws -> Data {
        return try processImageDataWithInfo(imageData).data
    }
    
    /// Process image data before sending to server
    /// - Converts HEIC images to PNG
    /// - Returns original data for already supported formats
    /// - Returns: Tuple with (data, isConverted) where isConverted is true if the image was converted to PNG
    private func processImageDataWithInfo(_ imageData: Data) throws -> (data: Data, isConverted: Bool) {
        do {
            // Delegate to the ImageProcessor service
            return try imageProcessor.processImage(imageData)
        } catch let error as ImageProcessorError {
            // Convert ImageProcessorError to OCRError
            throw OCRError(error: error.message)
        } catch {
            // Re-throw any other errors
            throw error
        }
    }
}
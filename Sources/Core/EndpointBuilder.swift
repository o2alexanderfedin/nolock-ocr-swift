import Foundation

/// A utility for building API endpoint URLs in a standardized way
/// Used to centralize URL construction and parameter handling
public struct EndpointBuilder {
    /// Base URL for the API
    private let baseURL: URL
    
    /// Initialize a new endpoint builder
    /// - Parameter baseURL: The base URL for the API
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    /// Build an endpoint URL with path and query parameters
    /// - Parameters:
    ///   - path: Path component to append to the base URL
    ///   - parameters: Dictionary of query parameters
    /// - Returns: The complete URL
    /// - Throws: An OCRError if the URL is invalid
    public func buildURL(path: String, parameters: [String: String?]) throws -> URL {
        var urlComponents = URLComponents(string: baseURL.appendingPathComponent(path).absoluteString)!
        
        let queryItems = parameters.compactMap { (key, value) -> URLQueryItem? in
            guard let value = value else { return nil }
            return URLQueryItem(name: key, value: value)
        }
        
        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else {
            throw OCRError(error: "Invalid URL")
        }
        
        return url
    }
    
    /// Build an endpoint URL for document processing (check, receipt, or generic document)
    /// - Parameters:
    ///   - endpoint: The endpoint type (check, receipt, or document)
    ///   - parameters: Additional parameters (format, filename, etc.)
    /// - Returns: The complete URL
    /// - Throws: An OCRError if the URL is invalid
    public func buildProcessingURL(endpoint: Endpoint, parameters: [String: String?] = [:]) throws -> URL {
        var combinedParams = parameters
        
        // Add endpoint-specific parameters
        switch endpoint {
        case .document(let docType):
            combinedParams["type"] = docType.rawValue
        case .check, .receipt, .health:
            // No additional parameters needed
            break
        }
        
        return try buildURL(path: endpoint.path, parameters: combinedParams)
    }
    
    /// Available API endpoints
    public enum Endpoint {
        /// Check processing endpoint
        case check
        /// Receipt processing endpoint
        case receipt
        /// Generic document processing endpoint
        case document(type: DocumentType)
        /// Health check endpoint
        case health
        
        /// Path component for the endpoint
        var path: String {
            switch self {
            case .check:
                return "check"
            case .receipt:
                return "receipt"
            case .document:
                return "process"
            case .health:
                return "health"
            }
        }
    }
}
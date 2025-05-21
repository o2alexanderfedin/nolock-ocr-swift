import Foundation

/// Confidence scores for the OCR process and data extraction
public struct Confidence: Codable {
    /// OCR process confidence score (0-1)
    public let ocr: Double
    
    /// Data extraction confidence score (0-1)
    public let extraction: Double
    
    /// Overall confidence score (0-1)
    public let overall: Double
}

/// Error response returned by the API
public struct OCRError: Codable, Error {
    /// Error message
    public let error: String
}

/// Document types that can be processed
public enum DocumentType: String, Codable {
    case receipt
    case check
    case auto
}

/// Format types for document processing
public enum DocumentFormat: String, Codable {
    case image
    case pdf
    case heic
}
import Foundation

// No need to export anything else, all files are in the same module

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
public enum DocumentType: String, Codable, SafeDecodableEnum {
    case receipt
    case check
    case auto
    
    /// Default value to use when an unknown value is encountered
    public static var defaultValue: DocumentType { .auto }
}

/// Format types for document processing
public enum DocumentFormat: String, Codable, SafeDecodableEnum {
    case image
    case pdf
    case heic
    
    /// Default value to use when an unknown value is encountered
    public static var defaultValue: DocumentFormat { .image }
}
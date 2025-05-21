import Foundation

/// Protocol that defines an item that can be processed by the OCR service
public protocol OCRProcessable: Identifiable {
    /// The image data to be processed
    var imageData: Data { get }
    
    /// Type of document to process
    var documentType: DocumentType { get }
    
    /// Additional metadata to include with the request
    var metadata: [String: Any] { get }
}
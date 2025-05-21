import Foundation

/// Default implementation of OCRProcessable
public class OCRStorageItem: OCRProcessable, Identifiable {
    /// Unique identifier
    public let id: String
    
    /// The image data to process
    public let imageData: Data
    
    /// Type of document to process
    public let documentType: DocumentType
    
    /// Additional metadata
    public var metadata: [String: Any]
    
    /// Initialize a new storage item
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - imageData: The image data to process
    ///   - documentType: Type of document (receipt, check, auto)
    ///   - metadata: Additional metadata
    public init(
        id: String,
        imageData: Data,
        documentType: DocumentType = .auto,
        metadata: [String: Any] = [:]
    ) {
        self.id = id
        self.imageData = imageData
        self.documentType = documentType
        self.metadata = metadata
    }
}
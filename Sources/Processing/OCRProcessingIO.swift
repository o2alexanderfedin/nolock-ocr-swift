import Foundation

/// Protocol that defines the I/O operations for the OCR processing service
public protocol OCRProcessingIO {
    /// StorageItem represents an item that can be processed by the OCR service
    associatedtype Item
    
    /// Get the next item to be processed
    /// - Returns: An optional item. If nil, indicates no more items to process
    func getNextItemToProcess() async throws -> Item?
    
    /// Notify that an item has been processed
    /// - Parameters:
    ///   - item: The item that was processed
    ///   - result: The result of processing (success or failure)
    func itemProcessed(item: Item, result: Result<Any, Error>) async throws
}
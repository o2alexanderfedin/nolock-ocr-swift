import Foundation
@testable import NolockOCR

/// Mock implementation of OCRProcessable for testing
class ProcessingMockOCRItem: OCRProcessable, Identifiable {
    let id: String
    let imageData: Data
    let documentType: DocumentType
    var metadata: [String: Any]
    
    init(id: String, documentType: DocumentType = .receipt, metadata: [String: Any] = [:]) {
        self.id = id
        self.documentType = documentType
        self.metadata = metadata
        
        // Create mock image data
        var data = Data(capacity: 1024)
        for i in 0..<1024 {
            data.append(UInt8(i % 256))
        }
        self.imageData = data
    }
    
    static func createReceiptItem(id: String? = nil) -> ProcessingMockOCRItem {
        let itemId = id ?? "receipt-\(UUID().uuidString.prefix(8))"
        return ProcessingMockOCRItem(id: itemId, documentType: .receipt)
    }
    
    static func createCheckItem(id: String? = nil) -> ProcessingMockOCRItem {
        let itemId = id ?? "check-\(UUID().uuidString.prefix(8))"
        return ProcessingMockOCRItem(id: itemId, documentType: .check)
    }
    
    static func createAutoItem(id: String? = nil) -> ProcessingMockOCRItem {
        let itemId = id ?? "auto-\(UUID().uuidString.prefix(8))"
        return ProcessingMockOCRItem(id: itemId, documentType: .auto)
    }
}

/// Manual mock implementation of OCRProcessingIO for testing
class MockProcessingIO: OCRProcessingIO {
    typealias Item = ProcessingMockOCRItem
    
    // Queue management
    var items: [Item] = []
    var processedItems: [Item] = []
    var processedResults: [Result<Any, Error>] = []
    
    // Control flags
    var shouldFailGetNext = false
    var shouldFailProcessed = false
    var customError: Error?
    var processingDelay: TimeInterval = 0
    
    // Tracking properties
    var getNextItemCallCount = 0
    var itemProcessedCallCount = 0
    
    // Queue behavior control
    var emptyQueueOnFirstCall = false
    var dynamicallyAddItems = false
    var itemsToAddWhenEmpty: [Item] = []
    
    // Callback handlers
    var onItemProcessed: ((Item, Result<Any, Error>) -> Void)?
    var onGetNextItem: (() -> Void)?
    
    func getNextItemToProcess() async throws -> Item? {
        getNextItemCallCount += 1
        onGetNextItem?()
        
        if shouldFailGetNext {
            if let customError = customError {
                throw customError
            } else {
                throw NSError(domain: "MockIO", code: 1, userInfo: [NSLocalizedDescriptionKey: "Simulated IO failure"])
            }
        }
        
        if processingDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
        }
        
        // Special behavior for the first call
        if emptyQueueOnFirstCall && getNextItemCallCount == 1 {
            return nil
        }
        
        // Get the next item from the queue
        if items.isEmpty {
            if dynamicallyAddItems && !itemsToAddWhenEmpty.isEmpty {
                items = itemsToAddWhenEmpty
                itemsToAddWhenEmpty = []
                return items.removeFirst()
            }
            return nil
        }
        
        return items.removeFirst()
    }
    
    func itemProcessed(item: Item, result: Result<Any, Error>) async throws {
        itemProcessedCallCount += 1
        
        if shouldFailProcessed {
            if let customError = customError {
                throw customError
            } else {
                throw NSError(domain: "MockIO", code: 2, userInfo: [NSLocalizedDescriptionKey: "Simulated IO processing failure"])
            }
        }
        
        if processingDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
        }
        
        processedItems.append(item)
        processedResults.append(result)
        onItemProcessed?(item, result)
    }
    
    // Helper to add items to the queue
    func addItems(_ newItems: [Item]) {
        items.append(contentsOf: newItems)
    }
    
    // Helper to set items to add when the queue is empty
    func setItemsToAddWhenEmpty(_ newItems: [Item]) {
        itemsToAddWhenEmpty = newItems
        dynamicallyAddItems = true
    }
    
    // Reset tracking state
    func reset() {
        items = []
        processedItems = []
        processedResults = []
        getNextItemCallCount = 0
        itemProcessedCallCount = 0
        shouldFailGetNext = false
        shouldFailProcessed = false
        customError = nil
        processingDelay = 0
        emptyQueueOnFirstCall = false
        dynamicallyAddItems = false
        itemsToAddWhenEmpty = []
    }
}
import Foundation
import NolockOCR

/// Example of how to use OCRProcessingService for batch processing
class BatchProcessingExample: OCRProcessingIO {
    // MARK: - OCRProcessingIO Implementation
    
    typealias Item = OCRStorageItem
    
    // Queue of items to process
    private var itemQueue: [OCRStorageItem] = []
    
    // Processed results
    private var processedResults: [String: Result<Any, Error>] = [:]
    
    // Get the next item to process
    func getNextItemToProcess() async throws -> OCRStorageItem? {
        // Return nil if queue is empty
        if itemQueue.isEmpty {
            return nil
        }
        
        // Return and remove the first item
        return itemQueue.removeFirst()
    }
    
    // Process completed item
    func itemProcessed(item: OCRStorageItem, result: Result<Any, Error>) async throws {
        // Store result with item ID as key
        processedResults[item.id] = result
        
        // Print progress
        switch result {
        case .success:
            print("Successfully processed item \(item.id)")
        case .failure(let error):
            print("Failed to process item \(item.id): \(error)")
        }
    }
    
    // MARK: - Example Methods
    
    /// Add items to the processing queue
    func addItems(_ items: [OCRStorageItem]) {
        itemQueue.append(contentsOf: items)
    }
    
    /// Get results for a specific item
    func getResult(for itemId: String) -> Result<Any, Error>? {
        return processedResults[itemId]
    }
    
    /// Example method to run batch processing
    func runBatchProcessingExample() async {
        // Create a processing service
        let processingService = OCRProcessingService(
            io: self,
            environment: .development,
            processingInterval: 1.0 // Process one item per second
        )
        
        // Set up callbacks
        processingService.statusHandler = { status in
            switch status {
            case .idle:
                print("Processing service is idle")
            case .processing(let completed, let total):
                print("Processing: \(completed)/\(total) completed")
            case .completed:
                print("Processing completed")
            case .cancelled:
                print("Processing cancelled")
            case .error(let error):
                print("Processing error: \(error)")
            }
        }
        
        processingService.onCompleted = {
            print("Batch processing completed")
            print("Processed \(self.processedResults.count) items")
        }
        
        // Start processing
        processingService.start()
        
        // Later, if you want to add more items while processing is ongoing:
        // Add more items and notify the service
        DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) {
            // Create more items...
            let newItems = self.createMoreItems()
            // Add to queue
            self.addItems(newItems)
            // Notify processing service
            processingService.notifyWorkAvailable()
        }
        
        // To cancel processing
        DispatchQueue.global().asyncAfter(deadline: .now() + 30.0) {
            print("Cancelling processing")
            processingService.cancel()
        }
    }
    
    // Helper to create sample items
    private func createMoreItems() -> [OCRStorageItem] {
        var items: [OCRStorageItem] = []
        
        // Create sample image data (in real app, this would be actual images)
        let sampleData = Data(repeating: 0, count: 1024)
        
        // Create 5 items
        for i in 0..<5 {
            let item = OCRStorageItem(
                id: "batch-item-\(i)",
                imageData: sampleData,
                documentType: i % 2 == 0 ? .receipt : .check,
                metadata: ["batch": "second", "index": i]
            )
            items.append(item)
        }
        
        return items
    }
    
    // Initialize with sample items
    init() {
        // Create sample image data (in real app, this would be actual images)
        let sampleData = Data(repeating: 0, count: 1024)
        
        // Add 10 items to the queue
        for i in 0..<10 {
            let documentType: DocumentType = i % 3 == 0 ? .check : 
                                           i % 3 == 1 ? .receipt : .auto
            
            let item = OCRStorageItem(
                id: "item-\(i)",
                imageData: sampleData,
                documentType: documentType,
                metadata: ["batch": "first", "index": i]
            )
            
            itemQueue.append(item)
        }
    }
}

// Simple demonstration of how to use BatchProcessingExample
func runBatchProcessingExample() async {
    let example = BatchProcessingExample()
    await example.runBatchProcessingExample()
    
    // In a real app, you might wait for completion
    try? await Task.sleep(nanoseconds: 60_000_000_000) // Wait for 60 seconds
}

// Simple implementation of OCRProcessingIO for minimal example
class SimpleOCRStorage: OCRProcessingIO {
    typealias Item = OCRStorageItem
    
    // Queue of items to process
    var items: [OCRStorageItem] = []
    
    // Get the next item to process
    func getNextItemToProcess() async throws -> OCRStorageItem? {
        return items.isEmpty ? nil : items.removeFirst()
    }
    
    // Process completed item
    func itemProcessed(item: OCRStorageItem, result: Result<Any, Error>) async throws {
        print("Processed item \(item.id): \(result)")
    }
}

// Simple example usage:
func simpleProcessingExample() {
    // Create sample storage with items
    let storage = SimpleOCRStorage()
    
    // Add some sample items
    let sampleImageData = Data(repeating: 0, count: 1024) // Dummy data
    storage.items = [
        OCRStorageItem(id: "receipt-1", imageData: sampleImageData, documentType: .receipt),
        OCRStorageItem(id: "check-1", imageData: sampleImageData, documentType: .check),
        OCRStorageItem(id: "auto-1", imageData: sampleImageData, documentType: .auto)
    ]
    
    // Create processing service
    let processingService = OCRProcessingService(
        io: storage,
        environment: .production
    )
    
    // Set up status handler
    processingService.statusHandler = { status in
        print("Status: \(status)")
    }
    
    // Set up completion handler
    processingService.onCompleted = {
        print("All items processed")
    }
    
    // Start processing
    processingService.start()
}
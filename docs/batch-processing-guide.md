# Batch Processing with OCRProcessingService

This guide explains how to use the `OCRProcessingService` for batch processing of documents with the NolockOCR Swift package.

## Overview

The `OCRProcessingService` is designed to handle batch processing of OCR tasks with features like:

1. Controlled processing rate to respect API rate limits
2. Status updates during processing
3. Dynamic queue management with new item notifications
4. Cancellation support
5. Comprehensive error handling

## Prerequisites

Before using the OCRProcessingService, you need:

1. A class that implements the `OCRProcessingIO` protocol
2. Document data to process (checks, receipts, or other documents)
3. Basic understanding of Swift concurrency (async/await)

## Implementation Steps

### 1. Create an OCRProcessingIO Implementation

First, create a class that implements the `OCRProcessingIO` protocol:

```swift
class MyBatchProcessor: OCRProcessingIO {
    typealias Item = OCRStorageItem
    
    // Queue of items to process
    private var itemQueue: [OCRStorageItem] = []
    
    // Processed results
    private var processedResults: [String: Result<Any, Error>] = [:]
    
    // Get the next item to process - required by OCRProcessingIO
    func getNextItemToProcess() async throws -> OCRStorageItem? {
        // Return nil if queue is empty
        if itemQueue.isEmpty {
            return nil
        }
        
        // Return and remove the first item
        return itemQueue.removeFirst()
    }
    
    // Process completed item - required by OCRProcessingIO
    func itemProcessed(item: OCRStorageItem, result: Result<Any, Error>) async throws {
        // Store result with item ID as key
        processedResults[item.id] = result
        
        // Handle success or failure as needed
        switch result {
        case .success(let data):
            print("Successfully processed item \(item.id)")
        case .failure(let error):
            print("Failed to process item \(item.id): \(error)")
        }
    }
    
    // Helper method to add items to the queue
    func addItems(_ items: [OCRStorageItem]) {
        itemQueue.append(contentsOf: items)
    }
    
    // Helper method to get a result for a specific item
    func getResult(for itemId: String) -> Result<Any, Error>? {
        return processedResults[itemId]
    }
}
```

### 2. Create and Configure the Processing Service

Next, create and configure an instance of `OCRProcessingService`:

```swift
// Create your batch processor
let batchProcessor = MyBatchProcessor()

// Create the processing service
let processingService = OCRProcessingService(
    io: batchProcessor,
    environment: .production, // or .development, .staging, etc.
    processingInterval: 1.0 // Process one item per second
)

// Set up status handler to track progress
processingService.statusHandler = { status in
    switch status {
    case .idle:
        print("Service is idle")
    case .processing(let completed, let total):
        print("Processing \(completed)/\(total)")
    case .completed:
        print("Processing completed")
    case .cancelled:
        print("Processing cancelled")
    case .error(let error):
        print("Processing error: \(error)")
    }
}

// Set up completion handler
processingService.onCompleted = {
    print("Batch processing completed")
}
```

### 3. Add Items and Start Processing

Add items to your processor and start the service:

```swift
// Create some items to process
let receiptImage = getReceiptImageData() // Your method to get image data
let checkImage = getCheckImageData() // Your method to get image data

let items = [
    OCRStorageItem(
        id: "receipt-1",
        imageData: receiptImage,
        documentType: .receipt
    ),
    OCRStorageItem(
        id: "check-1",
        imageData: checkImage,
        documentType: .check
    )
]

// Add items to the processor
batchProcessor.addItems(items)

// Start processing
processingService.start()
```

### 4. Adding More Items During Processing

You can add more items while processing is ongoing:

```swift
// Add new items
let newItem = OCRStorageItem(
    id: "receipt-2",
    imageData: getAnotherReceiptImage(),
    documentType: .receipt
)

// Add to queue
batchProcessor.addItems([newItem])

// Notify service that new work is available
processingService.notifyWorkAvailable()
```

### 5. Cancelling Processing

To cancel the processing at any time:

```swift
// Cancel processing
processingService.cancel()
```

## Advanced Features

### Controlling Processing Rate

You can control the rate at which items are processed by adjusting the `processingInterval` parameter. This is useful for respecting API rate limits:

```swift
// Process one item every 2 seconds
let processingService = OCRProcessingService(
    io: batchProcessor,
    environment: .production,
    processingInterval: 2.0
)
```

### Handling Race Conditions

The service is designed to handle race conditions when new items are added while processing is ongoing. The `pendingWorkCounter` property tracks the number of items that have been added since processing started, ensuring that all items are processed.

### Error Handling

The service handles errors that occur during processing and passes them to your `itemProcessed` method. This allows you to implement custom error handling logic:

```swift
func itemProcessed(item: OCRStorageItem, result: Result<Any, Error>) async throws {
    switch result {
    case .success(let data):
        // Handle success
        if let checkResponse = data as? CheckResponse {
            // Handle check data
        } else if let receiptResponse = data as? ReceiptResponse {
            // Handle receipt data
        }
        
    case .failure(let error):
        if let ocrError = error as? OCRError {
            // Handle API-specific error
            print("OCR API Error: \(ocrError.error)")
            
            // Retry logic for certain errors
            if ocrError.error.contains("rate limit") {
                // Wait and retry later
            }
        } else if let urlError = error as? URLError {
            // Handle network-related errors
            switch urlError.code {
            case .notConnectedToInternet:
                // Handle connectivity issues
            case .timedOut:
                // Handle timeouts
            default:
                // Handle other network errors
            }
        } else {
            // Handle other errors
        }
    }
}
```

## Complete Example

For a complete example of batch processing with OCRProcessingService, see the [BatchProcessingExample.swift](../Examples/BatchProcessingExample.swift) file in the Examples directory.

## Best Practices

1. **Throttle Processing**: Use an appropriate `processingInterval` to avoid overwhelming the API service
2. **Implement Proper Error Handling**: Handle specific error types differently
3. **Use Persistent Storage**: In real applications, consider using persistent storage for your item queue
4. **Monitor Status**: Always implement the `statusHandler` to monitor processing status
5. **Implement Retry Logic**: For transient errors, consider implementing retry logic in your `itemProcessed` method
6. **Cancel Properly**: Always cancel the service when it's no longer needed to release resources
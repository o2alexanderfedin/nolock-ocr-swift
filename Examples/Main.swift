import Foundation
import NolockOCR

/**
 * NolockOCR Swift Example Runner
 *
 * This example demonstrates how to use the NolockOCR Swift client library
 * to process checks and receipts using the Nolock OCR API.
 *
 * Key features demonstrated:
 * - Creating an OCR client with different environment configurations
 * - Using both async/await and completion handler-based APIs
 * - Checking API health status
 * - Processing checks and receipts
 * - Handling success and error cases
 */
@main
struct OCRExampleRunner {
    // MARK: - Main entry point
    
    static func main() async throws {
        printHeader("NolockOCR Swift Examples", symbol: "🚀")
        
        // Create clients for different environments
        printHeader("Client Configuration Examples", symbol: "⚙️")
        demonstrateClientCreation()
        
        // Create a client that uses the Cloudflare worker for live testing
        let client = NolockOCR.createClient(
            environment: .custom(URL(string: "https://ocr-checks-worker.af-4a0.workers.dev")!),
            session: URLSession.shared
        )
        
        // Health check example (async version)
        printHeader("Health Check API (Async)", symbol: "🧪")
        await runHealthCheckExample(client: client)
        
        // Simulate completion handler-based example
        printHeader("Health Check API (Completion Handler)", symbol: "🧪")
        await runHealthCheckExampleWithCompletionHandler(client: client)
        
        // Example of processing a check
        printHeader("Check Processing API", symbol: "📋")
        print("Note: This is a demonstration of the API structure only.")
        print("Processing actual checks requires check image data.\n")
        exampleCheckProcessingCode()
        
        // Example of processing a receipt
        printHeader("Receipt Processing API", symbol: "🧾")
        print("Note: This is a demonstration of the API structure only.")
        print("Processing actual receipts requires receipt image data.\n")
        exampleReceiptProcessingCode()
        
        // Example of using the universal document processing endpoint
        printHeader("Universal Document Processing API", symbol: "📄")
        print("Note: This endpoint can process either checks or receipts.\n")
        exampleUniversalDocumentProcessingCode()
        
        // Error handling examples
        printHeader("Error Handling", symbol: "⚠️")
        exampleErrorHandlingCode()
        
        // Batch processing examples using OCRProcessingService
        printHeader("Batch Processing", symbol: "🔄")
        exampleBatchProcessingCode()
        
        printHeader("Examples Completed Successfully", symbol: "✅")
    }
    
    // MARK: - Batch Processing Examples
    
    static func exampleBatchProcessingCode() {
        print("""
        // Example code for batch processing using OCRProcessingService
        
        // 1. Create a custom class that implements OCRProcessingIO
        class BatchProcessor: OCRProcessingIO {
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
                    print("Successfully processed item \\(item.id)")
                case .failure(let error):
                    print("Failed to process item \\(item.id): \\(error)")
                }
            }
            
            // Add items to the queue
            func addItems(_ items: [OCRStorageItem]) {
                itemQueue.append(contentsOf: items)
            }
        }
        
        // 2. Create an instance of your processor
        let batchProcessor = BatchProcessor()
        
        // 3. Add some items to process
        let sampleData = Data(repeating: 0, count: 1024) // Sample image data
        let items = [
            OCRStorageItem(id: "receipt-1", imageData: sampleData, documentType: .receipt),
            OCRStorageItem(id: "check-1", imageData: sampleData, documentType: .check),
            OCRStorageItem(id: "receipt-2", imageData: sampleData, documentType: .receipt)
        ]
        batchProcessor.addItems(items)
        
        // 4. Create and configure the processing service
        let processingService = OCRProcessingService(
            io: batchProcessor,
            environment: .production,
            processingInterval: 1.0 // Process one item per second
        )
        
        // 5. Set up status handler
        processingService.statusHandler = { status in
            switch status {
            case .idle:
                print("Service is idle")
            case .processing(let completed, let total):
                print("Processing \\(completed)/\\(total)")
            case .completed:
                print("Processing completed")
            case .cancelled:
                print("Processing cancelled")
            case .error(let error):
                print("Processing error: \\(error)")
            }
        }
        
        // 6. Set up completion handler
        processingService.onCompleted = {
            print("Batch processing completed")
        }
        
        // 7. Start processing
        processingService.start()
        
        // 8. Later, add more items and notify the service
        // Add new items to the queue
        let newItems = [
            OCRStorageItem(id: "new-item-1", imageData: sampleData, documentType: .receipt)
        ]
        batchProcessor.addItems(newItems)
        
        // Notify service that new work is available
        processingService.notifyWorkAvailable()
        
        // 9. Cancel processing if needed
        processingService.cancel()
        """)
    }
    
    // MARK: - Client Creation Examples
    
    static func demonstrateClientCreation() {
        print("""
        // Create a client for the production environment
        let productionClient = NolockOCR.productionClient()
        
        // Create a client for the development environment
        let developmentClient = NolockOCR.developmentClient()
        
        // Create a client for local testing
        let localClient = NolockOCR.localClient()
        
        // Create a client with a custom URL and session configuration
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30 // 30 seconds timeout
        let session = URLSession(configuration: sessionConfig)
        
        let customClient = NolockOCR.createClient(
            environment: .custom(URL(string: "https://my-ocr-api.example.com")!),
            session: session
        )
        """)
        print()
    }
    
    // MARK: - Health Check Examples
    
    static func runHealthCheckExample(client: OCRClient) async {
        do {
            let health = try await client.getHealth()
            print("✅ API Status: \(health.status)")
            print("✅ Version: \(health.version)")
            print("✅ Server Time: \(health.timestamp)")
        } catch {
            print("❌ Error checking health: \(error)")
        }
    }
    
    static func runHealthCheckExampleWithCompletionHandler(client: OCRClient) async {
        // We need to create a continuation to bridge between the callback API and async/await
        await withCheckedContinuation { continuation in
            client.getHealth { result in
                switch result {
                case .success(let health):
                    print("✅ API Status: \(health.status)")
                    print("✅ Version: \(health.version)")
                    print("✅ Server Time: \(health.timestamp)")
                case .failure(let error):
                    print("❌ Error checking health: \(error)")
                }
                continuation.resume()
            }
        }
    }
    
    // MARK: - Check Processing Examples
    
    static func exampleCheckProcessingCode() {
        print("""
        // Example code for processing a check
        
        // 1. Create the client
        let client = NolockOCR.createClient()
        
        // 2. Get your check image data
        // This could come from UIImagePickerController, PHAsset, or any other source
        let imageData = getImageData() // Your function to get image data
        
        // 3A. Process check using async/await
        Task {
            do {
                let response = try await client.processCheck(imageData: imageData)
                
                // 4A. Access check data
                let check = response.data
                print("Check Number: \\(check.checkNumber)")
                print("Date: \\(check.date)")
                print("Payee: \\(check.payee)")
                print("Amount: $\\(check.amount)")
                if let bankName = check.bankName {
                    print("Bank Name: \\(bankName)")
                }
                
                // 5A. Access confidence scores
                let confidence = response.confidence
                print("OCR Confidence: \\(confidence.ocr)")
                print("Extraction Confidence: \\(confidence.extraction)")
                print("Overall Confidence: \\(confidence.overall)")
            } catch {
                print("Error: \\(error)")
            }
        }
        
        // 3B. Or using completion handlers
        client.processCheck(imageData: imageData) { result in
            switch result {
            case .success(let response):
                // 4B. Access check data
                let check = response.data
                print("Check Number: \\(check.checkNumber)")
                print("Amount: $\\(check.amount)")
                
                // 5B. Access confidence scores
                let confidence = response.confidence
                print("Overall Confidence: \\(confidence.overall)")
                
            case .failure(let error):
                print("Error: \\(error)")
            }
        }
        """)
    }
    
    // MARK: - Receipt Processing Examples
    
    static func exampleReceiptProcessingCode() {
        print("""
        // Example code for processing a receipt
        
        // 1. Create the client
        let client = NolockOCR.createClient()
        
        // 2. Get your receipt image data
        // This could come from UIImagePickerController, PHAsset, or any other source
        let imageData = getImageData() // Your function to get image data
        
        // 3A. Process receipt using async/await
        Task {
            do {
                let response = try await client.processReceipt(imageData: imageData)
                
                // 4A. Access receipt data
                let receipt = response.data
                print("Merchant: \\(receipt.merchant.name)")
                print("Date: \\(receipt.timestamp)")
                print("Total: \\(receipt.totals.total) \\(receipt.currency)")
                
                // 5A. Process line items if available
                if let items = receipt.items {
                    print("Items:")
                    for item in items {
                        print("- \\(item.description): $\\(item.totalPrice)")
                    }
                }
                
                // 6A. Access confidence scores
                let confidence = response.confidence
                print("OCR Confidence: \\(confidence.ocr)")
                print("Extraction Confidence: \\(confidence.extraction)")
                print("Overall Confidence: \\(confidence.overall)")
            } catch {
                print("Error: \\(error)")
            }
        }
        
        // 3B. Or using completion handlers
        client.processReceipt(imageData: imageData) { result in
            switch result {
            case .success(let response):
                // 4B. Access receipt data
                let receipt = response.data
                print("Merchant: \\(receipt.merchant.name)")
                print("Total: \\(receipt.totals.total) \\(receipt.currency)")
                
                // 5B. Access confidence scores
                let confidence = response.confidence
                print("Overall Confidence: \\(confidence.overall)")
                
            case .failure(let error):
                print("Error: \\(error)")
            }
        }
        """)
    }
    
    // MARK: - Universal Document Processing Example
    
    static func exampleUniversalDocumentProcessingCode() {
        print("""
        // Example code for universal document processing
        // This endpoint can process either checks or receipts
        
        // 1. Create the client
        let client = NolockOCR.createClient()
        
        // 2. Get your document image data
        let imageData = getImageData() // Your function to get image data
        
        // 3A. Process the document using async/await
        // Use DocumentType.check or DocumentType.receipt based on what you think the document is
        Task {
            do {
                let response = try await client.processDocument(
                    imageData: imageData,
                    type: .receipt // Provide hint about document type
                )
                
                // 4A. Check what type of document was detected
                print("Document was detected as a \\(response.documentType)")
                
                // 5A. Handle the data based on document type
                switch response.documentType {
                case .check:
                    if let check = response.data as? Check {
                        print("Check Number: \\(check.checkNumber)")
                        print("Amount: $\\(check.amount)")
                    }
                    
                case .receipt:
                    if let receipt = response.data as? Receipt {
                        print("Merchant: \\(receipt.merchant.name)")
                        print("Total: \\(receipt.totals.total) \\(receipt.currency)")
                    }
                }
                
                print("Overall Confidence: \\(response.confidence.overall)")
            } catch {
                print("Error: \\(error)")
            }
        }
        
        // 3B. Or using completion handlers
        client.processDocument(
            imageData: imageData,
            type: .receipt
        ) { result in
            switch result {
            case .success(let response):
                // 4B. Check what type of document was detected
                print("Document was detected as a \\(response.documentType)")
                
                // 5B. Handle the data based on document type
                switch response.documentType {
                case .check:
                    if let check = response.data as? Check {
                        print("Check Number: \\(check.checkNumber)")
                    }
                    
                case .receipt:
                    if let receipt = response.data as? Receipt {
                        print("Merchant: \\(receipt.merchant.name)")
                    }
                }
                
            case .failure(let error):
                print("Error: \\(error)")
            }
        }
        """)
    }
    
    // MARK: - Error Handling Examples
    
    static func exampleErrorHandlingCode() {
        print("""
        // Example code for handling errors
        
        // Using async/await with specific error handling
        Task {
            do {
                let response = try await client.processCheck(imageData: imageData)
                // Handle successful response...
            } catch let error as OCRError {
                // Handle API-specific error
                print("OCR API Error: \\(error.error)")
                
                // You can check for specific error types
                if error.error.contains("rate limit") {
                    print("Rate limit exceeded. Try again later.")
                } else if error.error.contains("invalid image") {
                    print("The image format is not supported.")
                }
            } catch let error as URLError {
                // Handle network-related errors
                switch error.code {
                case .notConnectedToInternet:
                    print("No internet connection.")
                case .timedOut:
                    print("Request timed out.")
                default:
                    print("Network error: \\(error.localizedDescription)")
                }
            } catch {
                // Handle other errors
                print("Unexpected error: \\(error.localizedDescription)")
            }
        }
        
        // Using completion handlers with specific error handling
        client.processCheck(imageData: imageData) { result in
            switch result {
            case .success(let response):
                // Handle successful response...
                
            case .failure(let error):
                if let ocrError = error as? OCRError {
                    // Handle API-specific error
                    print("OCR API Error: \\(ocrError.error)")
                } else if let urlError = error as? URLError {
                    // Handle network-related errors
                    print("Network error: \\(urlError.localizedDescription)")
                } else {
                    // Handle other errors
                    print("Unexpected error: \\(error.localizedDescription)")
                }
            }
        }
        """)
    }
    
    // MARK: - Helper Methods
    
    static func printHeader(_ text: String, symbol: String) {
        print("\n\(symbol) \(text)")
        print(String(repeating: "=", count: text.count + 3))
    }
}
import Foundation

/// A service that processes items for OCR using an IO interface
/// This helps with batch processing by respecting API rate limits and providing
/// progress tracking.
public class OCRProcessingService<IO: OCRProcessingIO> where IO.Item: OCRProcessable {
    // MARK: - Types
    
    /// Status of the processing service
    public enum ProcessingStatus {
        case idle
        case processing(completed: Int, total: Int)
        case completed
        case cancelled
        case error(Error)
    }
    
    /// Error types specific to the processing service
    public enum ProcessingError: Error {
        case cancelled
        case noMoreItems
        case ioError(Error)
    }
    
    // MARK: - Configuration Properties
    
    /// The OCR client to use for processing
    private let client: OCRClient
    
    /// The IO interface for getting items and reporting results
    private let io: IO
    
    /// Time interval between processing items (in seconds)
    private let processingInterval: TimeInterval
    
    // MARK: - State Properties
    
    /// Whether the service is currently processing items
    private var isProcessing = false
    
    /// Timer for processing items at intervals
    private var timer: Timer?
    
    /// Current status of the service
    private var status: ProcessingStatus = .idle {
        didSet {
            DispatchQueue.main.async {
                self.statusHandler?(self.status)
            }
        }
    }
    
    /// Number of completed items
    private var completedCount = 0
    
    /// Counter for pending work when service is busy
    private var pendingWorkCounter = 0
    
    /// Flag to track if the last getNextItemToProcess() returned nil
    private var noItemsAvailable = false
    
    /// Cancellation flag
    private var isCancelled = false
    
    // MARK: - Callback Handlers
    
    /// Called when processing is completed
    public var onCompleted: (() -> Void)?
    
    /// Called when the status changes
    public var statusHandler: ((ProcessingStatus) -> Void)?
    
    // MARK: - Initialization
    
    /// Initialize a new OCR processing service
    /// - Parameters:
    ///   - io: The IO interface for getting items and reporting results
    ///   - environment: The environment to use for the OCR client
    ///   - processingInterval: Time between processing items in seconds (default: 2.0)
    public init(
        io: IO,
        environment: ClientEnvironment = .production,
        processingInterval: TimeInterval = 2.0
    ) {
        // Get the session - either from OCRClient's shared test session or create a new one
        let session: URLSessionProtocol
        
        if let testSession = OCRClient.getSessionForTest() {
            // Use the test session if available
            session = testSession
        } else {
            // Create a custom session with extended timeout
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 120  // 2 minutes
            session = URLSession(configuration: config)
        }
        
        self.io = io
        self.client = OCRClient(environment: environment, session: session)
        self.processingInterval = processingInterval
    }
    
    // MARK: - Public Methods
    
    /// Start processing items
    public func start() {
        guard !isProcessing else { return }
        
        isProcessing = true
        isCancelled = false
        noItemsAvailable = false
        
        updateStatus()
        
        timer = Timer.scheduledTimer(withTimeInterval: processingInterval, 
                                     repeats: true) { [weak self] _ in
            self?.processNextItem()
        }
        
        // Process first item immediately
        processNextItem()
    }
    
    /// Cancel all processing
    public func cancel() {
        timer?.invalidate()
        timer = nil
        isCancelled = true
        isProcessing = false
        status = .cancelled
    }
    
    /// Notify service that work is available
    /// If the service is busy, increments a counter
    public func notifyWorkAvailable() {
        // Reset the flag since we now know there's work available
        noItemsAvailable = false
        
        if isProcessing {
            // Increment counter if busy
            pendingWorkCounter += 1
        } else {
            // Start processing if idle
            start()
        }
    }
    
    // MARK: - Private Methods
    
    /// Process the next item
    private func processNextItem() {
        // Check if processing was cancelled
        guard !isCancelled else {
            endProcessing(with: .cancelled)
            return
        }
        
        // Skip getNextItemToProcess() if previous call returned nil and pendingWorkCounter <= 0
        if noItemsAvailable && pendingWorkCounter <= 0 {
            endProcessing(with: .completed)
            return
        }
        
        Task {
            do {
                guard let item = try await io.getNextItemToProcess() else {
                    // No more items to process
                    noItemsAvailable = true
                    
                    await MainActor.run {
                        endProcessing(with: .completed)
                    }
                    return
                }
                
                // Reset the flag since we found an item
                noItemsAvailable = false
                
                // If we had pendingWorkCounter, decrement it
                if pendingWorkCounter > 0 {
                    pendingWorkCounter -= 1
                }
                
                // Process the item (IO should only return unprocessed items)
                do {
                    let result = try await processItem(item)
                    
                    // Update completion count
                    await MainActor.run {
                        completedCount += 1
                        updateStatus()
                    }
                    
                    // Notify IO about processed item
                    try await io.itemProcessed(item: item, result: result)
                } catch {
                    // Report failure to IO
                    await MainActor.run {
                        completedCount += 1
                        updateStatus()
                    }
                    
                    try await io.itemProcessed(item: item, result: .failure(error))
                    
                    // If processing was cancelled during item processing, stop now
                    if isCancelled {
                        await MainActor.run {
                            endProcessing(with: .cancelled)
                        }
                        return
                    }
                }
            } catch {
                // IO error occurred when getting next item
                await MainActor.run {
                    endProcessing(with: .error(ProcessingError.ioError(error)))
                }
                return
            }
        }
    }
    
    /// Process an item
    private func processItem(_ item: IO.Item) async throws -> Result<Any, Error> {
        // Check if processing was cancelled
        if isCancelled {
            throw ProcessingError.cancelled
        }
        
        // Process based on document type
        let response: Any
        
        switch item.documentType {
        case .receipt:
            response = try await client.processReceipt(
                imageData: item.imageData,
                filename: "receipt-\(String(describing: item.id))-\(UUID().uuidString.prefix(8)).jpg"
            )
        case .check:
            response = try await client.processCheck(
                imageData: item.imageData,
                filename: "check-\(String(describing: item.id))-\(UUID().uuidString.prefix(8)).jpg"
            )
        case .auto:
            response = try await client.processDocument(
                imageData: item.imageData,
                type: .receipt, // Start with receipt as the default type
                filename: "document-\(String(describing: item.id))-\(UUID().uuidString.prefix(8)).jpg"
            )
        }
        
        return .success(response)
    }
    
    
    
    /// End processing with the specified status
    private func endProcessing(with status: ProcessingStatus) {
        timer?.invalidate()
        timer = nil
        isProcessing = false
        self.status = status
        
        if case .completed = status {
            onCompleted?()
            
            // Check if there's pending work
            if pendingWorkCounter > 0 {
                // Don't reset pendingWorkCounter here since we'll decrement it in processNextItem
                // Reset the noItemsAvailable flag so we check for new items
                noItemsAvailable = false
                
                // Restart processing for pending work
                start()
            }
        }
    }
    
    /// Update status based on current progress
    private func updateStatus() {
        if !isProcessing {
            status = .idle
        } else {
            // Include pending work counter in the total
            status = .processing(completed: completedCount, total: completedCount + 1 + pendingWorkCounter)
        }
    }
}
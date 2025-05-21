import Foundation

/// Custom error type for task cancellation
public enum OCRClientError: Error, Equatable {
    case taskCancelled
    case noActiveTask
}
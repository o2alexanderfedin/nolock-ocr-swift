import Foundation

/// Available server environments for the API
public enum ClientEnvironment {
    /// Production server at ocr-checks-worker.af-4a0.workers.dev
    case production
    
    /// Development server at ocr-checks-worker-dev.af-4a0.workers.dev
    case development
    
    /// Local development server at http://localhost:8787
    case local
    
    /// Custom server URL
    case custom(URL)
    
    var url: URL {
        switch self {
        case .production:
            return URL(string: "https://ocr-checks-worker.af-4a0.workers.dev")!
        case .development:
            return URL(string: "https://ocr-checks-worker-dev.af-4a0.workers.dev")!
        case .local:
            return URL(string: "http://localhost:8787")!
        case .custom(let url):
            return url
        }
    }
}
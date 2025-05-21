import XCTest
@testable import NolockOCR
import Foundation

/// Simple production test for the OCRClient
/// This tests only the most basic functionality against the production API
/// with a small image to avoid hitting resource limits
class SimpleProductionTest: XCTestCase {
    
    // MARK: - Test Configuration
    
    // The production environment to test against
    private let productionURL = URL(string: "https://ocr-checks-worker.af-4a0.workers.dev")!
    
    // Test timeout interval
    private let testTimeoutInterval: TimeInterval = 30.0
    
    // Skip tests if not running in production mode
    private func skipIfNotProductionTest() throws {
        let testProd = ProcessInfo.processInfo.environment["OCR_TEST_PROD"]
        if testProd != "1" && testProd?.lowercased() != "true" {
            throw XCTSkip("Production tests are skipped unless OCR_TEST_PROD=1")
        }
    }
    
    // Helper function to load test image
    private func loadTestImage(filename: String = "rental-bill.jpg") -> Data? {
        // Base directories to search for test images
        let baseDirectories = [
            // When running from swift-proxy directory
            "../tests/fixtures/images",
            // When running from project root
            "tests/fixtures/images",
            // When running from Xcode
            "../../tests/fixtures/images"
        ]
        
        for baseDir in baseDirectories {
            let path = "\(baseDir)/\(filename)"
            if let imageData = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                print("Successfully loaded image from path: \(path)")
                return imageData
            } else {
                print("Failed to load image from path: \(path)")
            }
        }
        
        print("ERROR: Could not find test image \(filename) in any location")
        return nil
    }
    
    // MARK: - Tests
    
    // Integration test for health endpoint against production
    func testProductionHealthEndpoint() async throws {
        // Skip if not running production tests
        try skipIfNotProductionTest()
        
        // Create client using the production environment
        let client = OCRClient(environment: .custom(productionURL))
        
        // Run with timeout
        let result = try await withTimeout(seconds: testTimeoutInterval) {
            return try await client.getHealth()
        }
        
        // Verify we got a valid response
        XCTAssertEqual(result.status, "ok")
        XCTAssert(!result.version.isEmpty, "Version should not be empty")
        XCTAssert(!result.timestamp.isEmpty, "Timestamp should not be empty")
        
        // Log the response for debugging
        print("Health response: status=\(result.status), version=\(result.version), timestamp=\(result.timestamp)")
    }
    
    // Integration test for check processing against production with a small image
    func testProductionCheckProcessing() async throws {
        // Skip if not running production tests
        try skipIfNotProductionTest()
        
        // Skip the test if image file is not available
        guard let imageData = loadTestImage(filename: "fredmeyer-receipt.jpg") else {
            throw XCTSkip("Test image not available")
        }
        
        // Create client using the production environment
        let client = OCRClient(environment: .custom(productionURL))
        
        // Run with timeout
        let result = try await withTimeout(seconds: testTimeoutInterval) {
            return try await client.processCheck(
                imageData: imageData,
                filename: "test-production-\(UUID().uuidString.prefix(8)).jpg"
            )
        }
        
        // Verify we got valid check data
        XCTAssertGreaterThan(result.confidence.overall, 0, "Overall confidence should be positive")
        
        // Log the response for debugging
        print("Successfully processed check:")
        print("Check Number: \(result.data.checkNumber)")
        if let amount = result.data.amount {
            print("Amount: \(amount)")
        }
        print("Confidence: \(result.confidence.overall)")
    }
    
    // MARK: - Timeout Handling
    
    // Helper for running operations with timeouts
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await Task.detached { 
            let task = Task { 
                try await operation() 
            }
            
            let result = try await withTaskCancellationHandler {
                try await task.value
            } onCancel: {
                task.cancel()
            }
            
            return result
        }.value
    }
}
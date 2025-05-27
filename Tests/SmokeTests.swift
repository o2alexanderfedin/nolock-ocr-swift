import XCTest
import Foundation
@testable import NolockOCR

/// Smoke tests for the OCR API endpoints
/// These tests are designed to verify that the API endpoints are functional
/// and can successfully process at least one request out of multiple attempts
class SmokeTests: XCTestCase {
    
    // Define environments to test
    let environments: [ClientEnvironment] = [.production, .development]
    
    // Use a custom URL for staging if needed
    lazy var stagingEnvironment: ClientEnvironment = .custom(URL(string: "https://ocr-checks-worker-staging.af-4a0.workers.dev")!)
    
    // Configure retry settings
    let maxAttempts = 20
    let delayBetweenAttempts: TimeInterval = 1.0
    
    // Test resources - using mock image data to avoid file dependencies
    static let mockImageData = SmokeTests.createMockImageData()
    
    // MARK: - Helper methods
    
    /// Run a test with retries, ignoring timeouts
    /// - Parameters:
    ///   - testName: The name of the test
    ///   - maxAttempts: The maximum number of attempts to try
    ///   - test: The actual test to run, which returns a Bool indicating success
    func runWithRetries(testName: String, maxAttempts: Int = 20, test: () async throws -> Bool) async {
        var succeeded = false
        var lastError: Error?
        var attempts = 0
        
        while !succeeded && attempts < maxAttempts {
            attempts += 1
            print("🔄 \(testName): Attempt \(attempts)/\(maxAttempts)")
            
            do {
                succeeded = try await test()
                if succeeded {
                    print("✅ \(testName): Success on attempt \(attempts)")
                    break
                }
            } catch let error as NSError {
                lastError = error
                
                // Check if it's a timeout or resource limit error and ignore it
                let isTimeout = error.domain == NSURLErrorDomain && 
                                (error.code == NSURLErrorTimedOut || error.code == NSURLErrorCancelled)
                
                // Check for Cloudflare worker resource limits (error 1102)
                let isResourceLimit = error.localizedDescription.contains("Worker exceeded resource limits") || 
                                     error.localizedDescription.contains("Error 1102")
                
                if isTimeout {
                    print("⏱️ \(testName): Timeout on attempt \(attempts) - ignoring")
                    // Don't count timeouts as failures
                    continue
                } else if isResourceLimit {
                    print("⚠️ \(testName): Resource limit exceeded on attempt \(attempts) - ignoring")
                    // Don't count resource limits as failures
                    continue
                } else {
                    print("❌ \(testName): Error on attempt \(attempts): \(error)")
                }
            } catch {
                lastError = error
                print("❌ \(testName): Error on attempt \(attempts): \(error)")
            }
            
            // Short delay between attempts
            if attempts < maxAttempts {
                try? await Task.sleep(nanoseconds: UInt64(delayBetweenAttempts * 1_000_000_000))
            }
        }
        
        if !succeeded {
            if let error = lastError {
                XCTFail("\(testName) failed after \(attempts) attempts. Last error: \(error)")
            } else {
                XCTFail("\(testName) failed after \(attempts) attempts with no successful response")
            }
        }
        
        XCTAssertTrue(succeeded, "\(testName) should succeed at least once")
    }
    
    /// Create mock image data for testing
    /// - Returns: Data containing mock image bytes
    static func createMockImageData() -> Data {
        // Create a minimal valid JPEG-like data structure for testing
        // This creates a small data blob that APIs can process without errors
        let baseData = "SmokeTest-MockImage".data(using: .utf8) ?? Data()
        var mockData = Data()
        
        // Add JPEG-like header bytes to make it look like an image
        mockData.append(contentsOf: [0xFF, 0xD8, 0xFF, 0xE0]) // JPEG start marker
        
        // Add some mock content
        let targetSize = 2048 // 2KB of mock data
        while mockData.count < targetSize {
            mockData.append(baseData)
        }
        
        // Add JPEG end marker
        mockData.append(contentsOf: [0xFF, 0xD9])
        
        return Data(mockData.prefix(targetSize))
    }
    
    /// Get mock image data for testing
    /// - Parameter name: The name of the image (ignored, always returns mock data)
    /// - Returns: Mock image data
    func getMockImageData(named name: String = "mock_image") -> Data {
        return Self.mockImageData
    }
    
    // MARK: - Health endpoint tests
    
    /// Test the health endpoint for production and development
    func testHealthEndpoint() async throws {
        for environment in environments {
            let envName = String(describing: environment)
            await runWithRetries(testName: "Health check (\(envName))") {
                let client = OCRClient(environment: environment)
                
                do {
                    let health = try await client.getHealth()
                    // A successful health check should return "ok" status
                    return health.status == "ok"
                } catch {
                    throw error
                }
            }
        }
    }
    
    /// Test the health endpoint for staging
    func testHealthEndpointStaging() async throws {
        let environment = stagingEnvironment
        let envName = "staging"
        
        await runWithRetries(testName: "Health check (\(envName))") {
            let client = OCRClient(environment: environment)
            
            do {
                let health = try await client.getHealth()
                // A successful health check should return "ok" status
                return health.status == "ok"
            } catch {
                throw error
            }
        }
    }
    
    // MARK: - Check endpoint tests
    
    /// Test the check endpoint for production and development
    func testCheckEndpoint() async throws {
        for environment in environments {
            let envName = String(describing: environment)
            
            await runWithRetries(testName: "Check processing (\(envName))") {
                let client = OCRClient(environment: environment)
                
                do {
                    // Use mock check image data
                    let imageData = self.getMockImageData(named: "mock_check")
                    
                    // Process the check
                    let response = try await client.processCheck(imageData: imageData)
                    
                    // Validate response has basic check data
                    let check = response.data
                    
                    // Verify we got meaningful data (non-empty checkNumber or at least a valid amount)
                    let hasValidCheckNumber = !(check.checkNumber?.isEmpty ?? true)
                    let hasValidAmount = check.amount != nil && check.amount! > 0
                    
                    return hasValidCheckNumber || hasValidAmount
                } catch let error as NSError {
                    // Let the runWithRetries handle the error
                    throw error
                } catch {
                    throw error
                }
            }
        }
    }
    
    /// Test the check endpoint for staging
    func testCheckEndpointStaging() async throws {
        let environment = stagingEnvironment
        let envName = "staging"
        
        await runWithRetries(testName: "Check processing (\(envName))") {
            let client = OCRClient(environment: environment)
            
            do {
                // Use mock check image data
                let imageData = self.getMockImageData(named: "mock_check")
                
                // Process the check
                let response = try await client.processCheck(imageData: imageData)
                
                // Validate response has basic check data
                let check = response.data
                
                // Verify we got meaningful data (non-empty checkNumber or at least a valid amount)
                let hasValidCheckNumber = !(check.checkNumber?.isEmpty ?? true)
                let hasValidAmount = check.amount != nil && check.amount! > 0
                
                return hasValidCheckNumber || hasValidAmount
            } catch let error as NSError {
                // Let the runWithRetries handle the error
                throw error
            } catch {
                throw error
            }
        }
    }
    
    // MARK: - Receipt endpoint tests
    
    /// Test the receipt endpoint for production and development
    func testReceiptEndpoint() async throws {
        for environment in environments {
            let envName = String(describing: environment)
            
            await runWithRetries(testName: "Receipt processing (\(envName))") {
                let client = OCRClient(environment: environment)
                
                do {
                    // Use mock receipt image data
                    let imageData = self.getMockImageData(named: "mock_receipt")
                    
                    // Process the receipt
                    let response = try await client.processReceipt(imageData: imageData)
                    
                    // Validate response has basic receipt data
                    let receipt = response.data
                    
                    // Verify we got meaningful data (merchant name or non-zero total)
                    let hasValidMerchant = !(receipt.merchant?.name?.isEmpty ?? true)
                    let hasValidTotal = receipt.totals?.total != nil && receipt.totals!.total! > 0
                    
                    return hasValidMerchant || hasValidTotal
                } catch let error as NSError {
                    // Let the runWithRetries handle the error
                    throw error
                } catch {
                    throw error
                }
            }
        }
    }
    
    /// Test the receipt endpoint for staging
    func testReceiptEndpointStaging() async throws {
        let environment = stagingEnvironment
        let envName = "staging"
        
        await runWithRetries(testName: "Receipt processing (\(envName))") {
            let client = OCRClient(environment: environment)
            
            do {
                // Use mock receipt image data
                let imageData = self.getMockImageData(named: "mock_receipt")
                
                // Process the receipt
                let response = try await client.processReceipt(imageData: imageData)
                
                // Validate response has basic receipt data
                let receipt = response.data
                
                // Verify we got meaningful data (merchant name or non-zero total)
                let hasValidMerchant = !(receipt.merchant?.name?.isEmpty ?? true)
                let hasValidTotal = receipt.totals?.total != nil && receipt.totals!.total! > 0
                
                return hasValidMerchant || hasValidTotal
            } catch let error as NSError {
                // Let the runWithRetries handle the error
                throw error
            } catch {
                throw error
            }
        }
    }
}
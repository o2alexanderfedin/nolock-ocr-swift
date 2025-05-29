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
    
    // Configure retry settings for CI/CD efficiency
    let maxAttempts = 3  // Reduced from 20 for faster CI/CD
    let delayBetweenAttempts: TimeInterval = 0.5  // Reduced from 1.0 second
    
    // Test resources - using mock image data to avoid file dependencies
    static let mockImageData = SmokeTests.createMockImageData()
    
    // MARK: - Helper methods
    
    /// Run a test with retries, ignoring timeouts
    /// - Parameters:
    ///   - testName: The name of the test
    ///   - maxAttempts: The maximum number of attempts to try
    ///   - test: The actual test to run, which returns a Bool indicating success
    func runWithRetries(testName: String, maxAttempts: Int = 3, test: () async throws -> Bool) async {
        let testId = UUID().uuidString.prefix(6)
        let testStartTime = Date()
        
        print("🧪 [ST-\(testId)] Starting smoke test: \(testName)")
        print("⚙️ [ST-\(testId)] Max attempts: \(maxAttempts), Delay between attempts: \(delayBetweenAttempts)s")
        
        var succeeded = false
        var lastError: Error?
        var attempts = 0
        var totalRetryTime: TimeInterval = 0
        
        while !succeeded && attempts < maxAttempts {
            attempts += 1
            let attemptStartTime = Date()
            
            print("🔄 [ST-\(testId)] \(testName): Attempt \(attempts)/\(maxAttempts)")
            
            do {
                succeeded = try await test()
                let attemptTime = Date().timeIntervalSince(attemptStartTime)
                
                if succeeded {
                    let totalTime = Date().timeIntervalSince(testStartTime)
                    print("✅ [ST-\(testId)] \(testName): SUCCESS on attempt \(attempts)")
                    print("⏱️ [ST-\(testId)] Attempt time: \(String(format: "%.3f", attemptTime))s, Total time: \(String(format: "%.3f", totalTime))s")
                    break
                } else {
                    print("❌ [ST-\(testId)] \(testName): Test returned false on attempt \(attempts) (took \(String(format: "%.3f", attemptTime))s)")
                }
            } catch let error as NSError {
                let attemptTime = Date().timeIntervalSince(attemptStartTime)
                lastError = error
                
                print("💥 [ST-\(testId)] \(testName): Error on attempt \(attempts) (took \(String(format: "%.3f", attemptTime))s)")
                print("🔍 [ST-\(testId)] Error details: \(error.localizedDescription)")
                print("🔍 [ST-\(testId)] Error domain: \(error.domain), code: \(error.code)")
                
                // Check if it's a timeout or resource limit error and ignore it
                let isTimeout = error.domain == NSURLErrorDomain && 
                                (error.code == NSURLErrorTimedOut || error.code == NSURLErrorCancelled)
                
                // Check for Cloudflare worker resource limits (error 1102)
                let isResourceLimit = error.localizedDescription.contains("Worker exceeded resource limits") || 
                                     error.localizedDescription.contains("Error 1102")
                
                if isTimeout {
                    print("⏱️ [ST-\(testId)] \(testName): TIMEOUT detected on attempt \(attempts) - ignoring and continuing")
                    print("🔍 [ST-\(testId)] Timeout type: \(error.code == NSURLErrorTimedOut ? "TimedOut" : "Cancelled")")
                    // Don't count timeouts as failures
                    continue
                } else if isResourceLimit {
                    print("⚠️ [ST-\(testId)] \(testName): RESOURCE LIMIT exceeded on attempt \(attempts) - ignoring and continuing")
                    // Don't count resource limits as failures
                    continue
                } else {
                    print("❌ [ST-\(testId)] \(testName): ACTUAL ERROR on attempt \(attempts)")
                }
            } catch {
                let attemptTime = Date().timeIntervalSince(attemptStartTime)
                lastError = error
                print("💥 [ST-\(testId)] \(testName): Unknown error on attempt \(attempts) (took \(String(format: "%.3f", attemptTime))s): \(error)")
            }
            
            // Short delay between attempts
            if attempts < maxAttempts {
                print("⏳ [ST-\(testId)] Waiting \(delayBetweenAttempts)s before next attempt...")
                let delayStart = Date()
                try? await Task.sleep(nanoseconds: UInt64(delayBetweenAttempts * 1_000_000_000))
                let actualDelay = Date().timeIntervalSince(delayStart)
                totalRetryTime += actualDelay
                print("✅ [ST-\(testId)] Delay complete (actual: \(String(format: "%.3f", actualDelay))s)")
            }
        }
        
        let totalTestTime = Date().timeIntervalSince(testStartTime)
        
        if !succeeded {
            print("❌ [ST-\(testId)] FINAL FAILURE: \(testName) failed after \(attempts) attempts")
            print("⏱️ [ST-\(testId)] Total test time: \(String(format: "%.3f", totalTestTime))s")
            print("⏱️ [ST-\(testId)] Total retry delay time: \(String(format: "%.3f", totalRetryTime))s")
            
            if let error = lastError {
                print("🔍 [ST-\(testId)] Last error: \(error)")
                XCTFail("\(testName) failed after \(attempts) attempts. Last error: \(error)")
            } else {
                print("🔍 [ST-\(testId)] No error recorded, test returned false")
                XCTFail("\(testName) failed after \(attempts) attempts with no successful response")
            }
        } else {
            print("🎉 [ST-\(testId)] FINAL SUCCESS: \(testName) completed successfully")
            print("⏱️ [ST-\(testId)] Total test time: \(String(format: "%.3f", totalTestTime))s")
            print("⏱️ [ST-\(testId)] Total retry delay time: \(String(format: "%.3f", totalRetryTime))s")
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
        print("🏥 Starting health endpoint tests for \(environments.count) environments")
        
        for environment in environments {
            let envName = String(describing: environment)
            print("🌍 Testing environment: \(envName)")
            
            await runWithRetries(testName: "Health check (\(envName))") {
                print("🔗 Creating OCRClient for environment: \(envName)")
                let client = OCRClient(environment: environment)
                
                do {
                    print("💊 Calling getHealth() for \(envName)")
                    let health = try await client.getHealth()
                    print("📊 Health response for \(envName): status=\(health.status), timestamp=\(health.timestamp), version=\(health.version)")
                    // A successful health check should return "ok" status
                    let success = health.status == "ok"
                    print("✅ Health check result for \(envName): \(success ? "SUCCESS" : "FAILURE")")
                    return success
                } catch {
                    print("💥 Health check error for \(envName): \(error)")
                    throw error
                }
            }
        }
        
        print("🏁 Health endpoint tests completed for all environments")
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
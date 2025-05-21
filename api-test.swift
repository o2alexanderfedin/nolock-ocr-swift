import Foundation

// URLs
let baseURL = "https://ocr-checks-worker.af-4a0.workers.dev"
let healthURL = "\(baseURL)/health"
let checkURL = "\(baseURL)/check?format=image"
let receiptURL = "\(baseURL)/receipt?format=image"

// Image path
let imagePath = "/Users/alexanderfedin/Projects/OCRChecksServer/tests/fixtures/images/fredmeyer-receipt.jpg"

// Function to make HTTP request
func makeRequest(url: String, method: String = "GET", data: Data? = nil) async throws -> (Data, HTTPURLResponse) {
    guard let url = URL(string: url) else {
        fatalError("Invalid URL: \(url)")
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = method
    
    if let data = data {
        request.httpBody = data
        request.setValue("image/*", forHTTPHeaderField: "Content-Type")
    }
    
    let (responseData, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
        fatalError("Not an HTTP response")
    }
    
    return (responseData, httpResponse)
}

// Function to load image
func loadImage() -> Data? {
    do {
        let imageData = try Data(contentsOf: URL(fileURLWithPath: imagePath))
        print("Successfully loaded image: \(imageData.count) bytes")
        return imageData
    } catch {
        print("Failed to load image: \(error)")
        return nil
    }
}

// Pretty print JSON
func prettyPrint(_ data: Data) {
    do {
        let json = try JSONSerialization.jsonObject(with: data)
        let prettyData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        let prettyString = String(data: prettyData, encoding: .utf8)
        print(prettyString ?? "Error decoding JSON")
    } catch {
        print("Error processing JSON: \(error)")
        if let str = String(data: data, encoding: .utf8) {
            print("Raw response: \(str)")
        }
    }
}

// Run all tests
func runAllTests() async {
    print("\n=== Testing Health API ===")
    do {
        let (data, response) = try await makeRequest(url: healthURL)
        print("Status code: \(response.statusCode)")
        prettyPrint(data)
    } catch {
        print("Health API Error: \(error)")
    }
    
    guard let imageData = loadImage() else {
        fatalError("Could not load test image")
    }
    
    print("\n=== Testing Check API ===")
    do {
        let (data, response) = try await makeRequest(url: checkURL, method: "POST", data: imageData)
        print("Status code: \(response.statusCode)")
        prettyPrint(data)
    } catch {
        print("Check API Error: \(error)")
    }
    
    print("\n=== Testing Receipt API ===")
    do {
        let (data, response) = try await makeRequest(url: receiptURL, method: "POST", data: imageData)
        print("Status code: \(response.statusCode)")
        prettyPrint(data)
    } catch {
        print("Receipt API Error: \(error)")
    }
    
    print("\n=== All tests completed ===")
}

// Main execution
Task {
    await runAllTests()
    // Keep the process alive until all async tasks complete
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        exit(0)
    }
}

// Run the run loop to keep the process alive
RunLoop.main.run(until: Date(timeIntervalSinceNow: 60))
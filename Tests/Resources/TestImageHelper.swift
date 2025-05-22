import Foundation
import XCTest

/// Helper for loading test images
public struct TestImageHelper {
    /// Load an image from the test resources
    public static func loadImageData(name: String) -> Data {
        // Get the bundle for the test target
        let bundle = Bundle.module
        
        // Get the URL for the resource
        guard let url = bundle.url(forResource: name, withExtension: nil) else {
            fatalError("Could not find test image: \(name)")
        }
        
        // Load the data
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Could not load test image: \(name)")
        }
        
        return data
    }
    
    /// Get JPEG test image data
    public static var jpegImage: Data { loadImageData(name: "test_image.jpg") }
    
    /// Get PNG test image data
    public static var pngImage: Data { loadImageData(name: "test_image.png") }
    
    /// Get mock HEIC test image data
    public static var heicImage: Data { loadImageData(name: "test_image.heic") }
}
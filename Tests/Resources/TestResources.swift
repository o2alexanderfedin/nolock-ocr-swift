import Foundation

/// Helper struct to load test resources
public struct TestResources {
    /// Load test image data from the resources directory
    /// - Parameter name: Name of the image file
    /// - Returns: Data for the requested image
    public static func loadTestImage(name: String) -> Data {
        let url = URL(fileURLWithPath: "/Users/alexanderfedin/Projects/OCRChecksServer/swift-proxy/Tests/Resources/\(name)")
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Could not load test image: \(name)")
        }
        return data
    }
    
    /// Get JPEG test image data
    public static var jpegImage: Data {
        loadTestImage(name: "test_image.jpg")
    }
    
    /// Get PNG test image data
    public static var pngImage: Data {
        loadTestImage(name: "test_image.png")
    }
    
    /// Get mock HEIC test image data
    public static var heicImage: Data {
        loadTestImage(name: "test_image.heic")
    }
}
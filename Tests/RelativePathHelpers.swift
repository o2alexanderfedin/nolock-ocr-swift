import Foundation

/// Helper functions for loading test images with relative paths
struct RelativePathHelpers {
    /// Finds test images using various relative paths
    /// - Parameter filename: The filename to look for
    /// - Returns: The image data if found, nil otherwise
    static func loadTestImage(filename: String) -> Data? {
        // Base directories to search for test images (relative paths only)
        let baseDirectories = [
            // Look in the local TestImages directory first
            "TestImages",
            // When running from different directories
            ".",
            "..",
            "../..",
            "../../.."
        ].flatMap { base -> [String] in
            return [
                "\(base)/TestImages",
                "\(base)/tests/fixtures/images",
                "\(base)/swift-proxy/TestImages"
            ]
        }
        
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
}
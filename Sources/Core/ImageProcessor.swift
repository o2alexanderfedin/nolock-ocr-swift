import Foundation

#if canImport(UIKit) && !os(macOS)
import UIKit
#endif

#if canImport(AppKit) && os(macOS)
import AppKit
import ImageIO
#endif

/// Protocol for image processing services
public protocol ImageProcessing {
    /// Processes an image, converting it to a suitable format if needed
    /// - Parameter imageData: Raw image data
    /// - Returns: Processed image data and whether conversion occurred
    /// - Throws: Error if processing fails
    func processImage(_ imageData: Data) throws -> (data: Data, isConverted: Bool)
    
    /// Detects if the image data is in HEIC format
    /// - Parameter imageData: Raw image data
    /// - Returns: Boolean indicating if the data is HEIC format
    func isHEICFormat(_ imageData: Data) -> Bool
}

/// Error type for image processing operations
public struct ImageProcessorError: Error, LocalizedError {
    /// The error message
    public let message: String
    
    /// Create a new image processor error
    /// - Parameter message: Error description
    public init(message: String) {
        self.message = message
    }
    
    public var errorDescription: String? {
        return message
    }
}

/// Service for processing images before sending to API
/// Handles format detection and conversion (e.g., HEIC to PNG)
public class ImageProcessor: ImageProcessing {
    /// Shared instance for convenience
    public static let shared = ImageProcessor()
    
    /// Initialize a new image processor
    public init() {}
    
    /// Process image data, converting to an API-compatible format if needed
    /// - Parameter imageData: Raw image data
    /// - Returns: Processed image data and whether conversion was performed
    /// - Throws: ImageProcessorError if processing fails
    public func processImage(_ imageData: Data) throws -> (data: Data, isConverted: Bool) {
        // Check if this is a HEIC image
        let isHEIC = isHEICFormat(imageData)
        
        if isHEIC {
            print("Converting HEIC image to PNG format")
            
            #if canImport(UIKit) && !os(macOS)
            // iOS approach - Use UIKit
            if let image = UIImage(data: imageData) {
                // Convert to PNG (lossless format)
                if let pngData = image.pngData() {
                    print("HEIC conversion successful: \(imageData.count) bytes → \(pngData.count) bytes")
                    return (pngData, true)
                }
                throw ImageProcessorError(message: "Failed to convert HEIC to PNG")
            }
            throw ImageProcessorError(message: "Failed to create UIImage from HEIC data")
            
            #elseif canImport(AppKit) && os(macOS)
            // macOS approach - Use AppKit and ImageIO
            if let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
               let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) {
                
                let nsImage = NSImage(cgImage: cgImage, size: .zero)
                if let tiffData = nsImage.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmap.representation(using: .png, properties: [:]) {
                    print("HEIC conversion successful: \(imageData.count) bytes → \(pngData.count) bytes")
                    return (pngData, true)
                }
                throw ImageProcessorError(message: "Failed to convert HEIC to PNG")
            }
            throw ImageProcessorError(message: "Failed to create image from HEIC data")
            
            #else
            // For other platforms, provide a warning
            print("Warning: HEIC conversion is not supported on this platform. Image may not be processed correctly.")
            return (imageData, false)
            #endif
        }
        
        // Return original data for already supported formats
        return (imageData, false)
    }
    
    /// Detect if the image data is in HEIC format
    /// - Parameter imageData: Raw image data
    /// - Returns: Boolean indicating if the data is HEIC format
    public func isHEICFormat(_ imageData: Data) -> Bool {
        // HEIC files start with the 'ftyp' box followed by a brand like 'heic', 'heix', 'hevc', 'hevx'
        // We'll check for the 'ftyp' marker followed by one of these brands
        
        // Need at least 12 bytes to check the format
        guard imageData.count >= 12 else { return false }
        
        // HEIC format check
        // The 'ftyp' box is at position 4, and the brand follows it
        let ftypRange = 4..<8
        let brandRange = 8..<12
        
        if let ftypString = String(data: imageData.subdata(in: ftypRange), encoding: .ascii),
           ftypString == "ftyp" {
            
            if let brandString = String(data: imageData.subdata(in: brandRange), encoding: .ascii) {
                // Check for HEIC related brands
                let heicBrands = ["heic", "heix", "hevc", "hevx"]
                for brand in heicBrands {
                    if brandString.hasPrefix(brand) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
}
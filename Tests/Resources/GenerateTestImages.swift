import Foundation
#if canImport(UIKit) && !os(macOS)
import UIKit
#elseif canImport(AppKit) && os(macOS)
import AppKit
#endif

/// Utility to generate test images in different formats
/// Run this script to create test image resources
struct GenerateTestImages {
    static func run() {
        generateJPEG()
        generatePNG()
        // HEIC requires actual images - can't generate programmatically as easily
        // We'll use sample HEIC data instead for testing
        generateHEICHeader()
    }
    
    /// Generate a simple JPEG test image
    static func generateJPEG() {
        #if canImport(UIKit) && !os(macOS)
        // iOS approach
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.blue.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Draw text
        let text = "JPEG Test"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.white
        ]
        text.draw(at: CGPoint(x: 10, y: 40), withAttributes: attributes)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            let url = URL(fileURLWithPath: "Tests/Resources/test_image.jpg")
            try? jpegData.write(to: url)
            print("JPEG test image created at: \(url.path)")
        }
        #elseif canImport(AppKit) && os(macOS)
        // macOS approach
        let size = CGSize(width: 100, height: 100)
        let image = NSImage(size: size)
        
        image.lockFocus()
        NSColor.blue.set()
        NSRect(origin: .zero, size: size).fill()
        
        // Draw text
        let text = "JPEG Test" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.white
        ]
        text.draw(at: NSPoint(x: 10, y: 40), withAttributes: attributes)
        
        image.unlockFocus()
        
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let jpegData = bitmap.representation(using: .jpeg, properties: [:]) {
            let url = URL(fileURLWithPath: "/Users/alexanderfedin/Projects/OCRChecksServer/swift-proxy/Tests/Resources/test_image.jpg")
            try? jpegData.write(to: url)
            print("JPEG test image created at: \(url.path)")
        }
        #endif
    }
    
    /// Generate a simple PNG test image
    static func generatePNG() {
        #if canImport(UIKit) && !os(macOS)
        // iOS approach
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Draw text
        let text = "PNG Test"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.white
        ]
        text.draw(at: CGPoint(x: 10, y: 40), withAttributes: attributes)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        if let pngData = image.pngData() {
            let url = URL(fileURLWithPath: "Tests/Resources/test_image.png")
            try? pngData.write(to: url)
            print("PNG test image created at: \(url.path)")
        }
        #elseif canImport(AppKit) && os(macOS)
        // macOS approach
        let size = CGSize(width: 100, height: 100)
        let image = NSImage(size: size)
        
        image.lockFocus()
        NSColor.red.set()
        NSRect(origin: .zero, size: size).fill()
        
        // Draw text
        let text = "PNG Test" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.white
        ]
        text.draw(at: NSPoint(x: 10, y: 40), withAttributes: attributes)
        
        image.unlockFocus()
        
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            let url = URL(fileURLWithPath: "/Users/alexanderfedin/Projects/OCRChecksServer/swift-proxy/Tests/Resources/test_image.png")
            try? pngData.write(to: url)
            print("PNG test image created at: \(url.path)")
        }
        #endif
    }
    
    /// Generate a mock HEIC header data
    static func generateHEICHeader() {
        // Create mock HEIC data with the right signature for testing
        // This isn't a valid HEIC file, but has the signature that our detector checks for
        var mockHEICData = Data([0x00, 0x00, 0x00, 0x20]) // Size bytes
        mockHEICData.append(contentsOf: "ftyp".utf8) // ftyp box
        mockHEICData.append(contentsOf: "heic".utf8) // heic brand
        mockHEICData.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // More data
        mockHEICData.append(contentsOf: [0x6D, 0x69, 0x66, 0x31]) // Some additional data
        
        // Add more data to make it a bit larger
        for _ in 0..<100 {
            mockHEICData.append(contentsOf: [0x00, 0x01, 0x02, 0x03])
        }
        
        let url = URL(fileURLWithPath: "/Users/alexanderfedin/Projects/OCRChecksServer/swift-proxy/Tests/Resources/test_image.heic")
        try? mockHEICData.write(to: url)
        print("Mock HEIC file created at: \(url.path)")
    }
}

/// Main function to run the generator
/// - Note: Uncomment the line below to generate test images when needed
/// ```
/// GenerateTestImages.run()
/// ```
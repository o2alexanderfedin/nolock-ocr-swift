import XCTest
@testable import NolockOCR

final class ImageProcessorTests: XCTestCase {
    
    // MARK: - Properties
    
    var imageProcessor: ImageProcessor!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        imageProcessor = ImageProcessor()
    }
    
    override func tearDown() {
        imageProcessor = nil
        super.tearDown()
    }
    
    // MARK: - HEIC Detection Tests
    
    func testIsHEICFormatWithEmptyData() {
        let emptyData = Data()
        XCTAssertFalse(imageProcessor.isHEICFormat(emptyData), "Empty data should not be detected as HEIC")
    }
    
    func testIsHEICFormatWithSmallData() {
        let smallData = Data([0, 1, 2, 3, 4, 5])
        XCTAssertFalse(imageProcessor.isHEICFormat(smallData), "Small data should not be detected as HEIC")
    }
    
    func testIsHEICFormatWithNonHEICData() {
        // Creating mock JPEG data (not actual JPEG, just the signature)
        let jpegData = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01])
        XCTAssertFalse(imageProcessor.isHEICFormat(jpegData), "JPEG data should not be detected as HEIC")
    }
    
    func testIsHEICFormatWithMockHEICData() {
        // Creating mock HEIC data with the right signature
        var mockHEICData = Data([0x00, 0x00, 0x00, 0x00]) // Size bytes
        mockHEICData.append(contentsOf: "ftyp".utf8) // ftyp box
        mockHEICData.append(contentsOf: "heic".utf8) // heic brand
        mockHEICData.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // More data
        
        XCTAssertTrue(imageProcessor.isHEICFormat(mockHEICData), "HEIC data should be correctly detected")
    }
    
    func testIsHEICFormatWithAlternativeBrands() {
        // Test with other HEIC-related brands
        let brands = ["heix", "hevc", "hevx"]
        
        for brand in brands {
            var mockData = Data([0x00, 0x00, 0x00, 0x00]) // Size bytes
            mockData.append(contentsOf: "ftyp".utf8) // ftyp box
            mockData.append(contentsOf: brand.utf8) // brand
            mockData.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // More data
            
            XCTAssertTrue(imageProcessor.isHEICFormat(mockData), "\(brand) should be detected as HEIC format")
        }
    }
    
    // MARK: - Image Processing Tests
    
    func testProcessImageWithJPEGData() throws {
        // Mock JPEG data
        let jpegData = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01])
        let (processedData, isConverted) = try imageProcessor.processImage(jpegData)
        
        XCTAssertEqual(processedData, jpegData, "JPEG data should not be modified")
        XCTAssertFalse(isConverted, "JPEG should not trigger conversion")
    }
    
    // Due to platform dependencies with UIKit/AppKit, we can only perform limited tests without mocking
    // the platform-specific image libraries
    
    // MARK: - Error Tests
    
    func testImageProcessorErrorDescription() {
        let error = ImageProcessorError(message: "Test error message")
        XCTAssertEqual(error.errorDescription, "Test error message")
    }
}
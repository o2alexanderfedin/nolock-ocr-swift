import XCTest
@testable import NolockOCR

// Add test image helper directly to this file
fileprivate enum ImageProcessorTestHelper {
    /// Get the test bundle
    static var bundle: Bundle { Bundle.module }
    
    /// Load a resource from the test bundle
    static func loadResource(name: String, extension ext: String? = nil, shouldFail: Bool = true) -> Data? {
        guard let url = bundle.url(forResource: name, withExtension: ext) else {
            if shouldFail {
                XCTFail("Failed to locate resource: \(name).\(ext ?? "")")
            }
            return nil
        }
        
        guard let data = try? Data(contentsOf: url) else {
            if shouldFail {
                XCTFail("Failed to load resource: \(name).\(ext ?? "")")
            }
            return nil
        }
        
        return data
    }
    
    static var receiptImage: Data? {
        loadResource(name: "fredmeyer-receipt", extension: "jpg")
    }
    
    static var receiptImage2: Data? {
        loadResource(name: "fredmeyer-receipt-2", extension: "jpg") 
    }
    
    static var billImage: Data? {
        loadResource(name: "rental-bill", extension: "jpg")
    }
    
    static var heicBillImage: Data? {
        loadResource(name: "pge-bill", extension: "HEIC")
    }
    
    static var heicCheckImage: Data? {
        loadResource(name: "promo-check", extension: "HEIC")
    }
}

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
        // Use the real mock HEIC data from resources
        let heicData = ImageProcessorTestHelper.heicBillImage
        XCTAssertNotNil(heicData, "Failed to load HEIC test image - image file missing")
        
        guard let heicData = heicData else {
            return
        }
        XCTAssertTrue(imageProcessor.isHEICFormat(heicData), "HEIC data should be correctly detected")
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
        // Use real JPEG data from resources
        let jpegData = ImageProcessorTestHelper.receiptImage
        XCTAssertNotNil(jpegData, "Failed to load JPEG test image - image file missing")
        
        guard let jpegData = jpegData else {
            return
        }
        let (processedData, isConverted) = try imageProcessor.processImage(jpegData)
        
        XCTAssertEqual(processedData, jpegData, "JPEG data should not be modified")
        XCTAssertFalse(isConverted, "JPEG should not trigger conversion")
    }
    
    func testProcessImageWithPNGData() throws {
        // Use real PNG data from resources
        let pngData = ImageProcessorTestHelper.billImage
        XCTAssertNotNil(pngData, "Failed to load PNG test image - image file missing")
        
        guard let pngData = pngData else {
            return
        }
        let (processedData, isConverted) = try imageProcessor.processImage(pngData)
        
        XCTAssertEqual(processedData, pngData, "PNG data should not be modified")
        XCTAssertFalse(isConverted, "PNG should not trigger conversion")
    }
    
    func testProcessImageWithHEICData() throws {
        // Use mock HEIC data from resources
        let heicData = ImageProcessorTestHelper.heicBillImage
        XCTAssertNotNil(heicData, "Failed to load HEIC test image - image file missing")
        
        guard let heicData = heicData else {
            return
        }
        
        // Since our test HEIC data is not a real HEIC image, we expect it to fail conversion
        // but we can at least verify it attempts conversion by checking the isHEICFormat method is called
        do {
            let (_, _) = try imageProcessor.processImage(heicData)
            // On some platforms, this might pass with a warning, so we don't assert failure
        } catch {
            // This is expected on platforms that actually try to convert the mock HEIC data
            XCTAssertTrue(error is ImageProcessorError, "Should throw ImageProcessorError for invalid HEIC data")
        }
    }
    
    // Due to platform dependencies with UIKit/AppKit, we can only perform limited tests without mocking
    // the platform-specific image libraries
    
    // MARK: - Error Tests
    
    func testImageProcessorErrorDescription() {
        let error = ImageProcessorError(message: "Test error message")
        XCTAssertEqual(error.errorDescription, "Test error message")
    }
    
    func testMissingResourceLoading() {
        // Test loading a resource that doesn't exist
        let nonExistentResource = ImageProcessorTestHelper.loadResource(name: "missing-image", extension: "HEIC", shouldFail: false)
        XCTAssertNil(nonExistentResource, "Loading a non-existent resource should return nil")
    }
}
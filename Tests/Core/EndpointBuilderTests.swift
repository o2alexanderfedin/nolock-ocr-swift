import XCTest
@testable import NolockOCR

final class EndpointBuilderTests: XCTestCase {
    
    // MARK: - Properties
    
    let baseURL = URL(string: "https://example.com/api")!
    var builder: EndpointBuilder!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        builder = EndpointBuilder(baseURL: baseURL)
    }
    
    override func tearDown() {
        builder = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testBuildBasicURL() throws {
        let url = try builder.buildURL(path: "test", parameters: [:])
        XCTAssertEqual(url.absoluteString, "https://example.com/api/test")
    }
    
    func testBuildURLWithParameters() throws {
        let url = try builder.buildURL(
            path: "test", 
            parameters: ["param1": "value1", "param2": "value2"]
        )
        
        // URL components may reorder parameters, so we check for both parameters individually
        XCTAssertTrue(url.absoluteString.contains("param1=value1"))
        XCTAssertTrue(url.absoluteString.contains("param2=value2"))
        XCTAssertTrue(url.absoluteString.hasPrefix("https://example.com/api/test?"))
    }
    
    func testBuildURLWithNilParameters() throws {
        let url = try builder.buildURL(
            path: "test", 
            parameters: ["param1": "value1", "optional": nil]
        )
        
        XCTAssertEqual(
            url.absoluteString,
            "https://example.com/api/test?param1=value1"
        )
    }
    
    func testBuildCheckEndpoint() throws {
        let url = try builder.buildProcessingURL(
            endpoint: .check,
            parameters: ["format": "image", "filename": "test.jpg"]
        )
        
        // URL components may reorder parameters, so we check for all parameters individually
        XCTAssertTrue(url.absoluteString.contains("format=image"))
        XCTAssertTrue(url.absoluteString.contains("filename=test.jpg"))
        XCTAssertTrue(url.absoluteString.hasPrefix("https://example.com/api/check?"))
    }
    
    func testBuildReceiptEndpoint() throws {
        let url = try builder.buildProcessingURL(
            endpoint: .receipt,
            parameters: ["format": "image"]
        )
        
        XCTAssertEqual(
            url.absoluteString,
            "https://example.com/api/receipt?format=image"
        )
    }
    
    func testBuildDocumentEndpoint() throws {
        let url = try builder.buildProcessingURL(
            endpoint: .document(type: .check),
            parameters: ["format": "image", "filename": "test.jpg"]
        )
        
        // URL components may reorder parameters, so we check for all parameters individually
        XCTAssertTrue(url.absoluteString.contains("type=check"))
        XCTAssertTrue(url.absoluteString.contains("format=image"))
        XCTAssertTrue(url.absoluteString.contains("filename=test.jpg"))
        XCTAssertTrue(url.absoluteString.hasPrefix("https://example.com/api/process?"))
    }
    
    func testBuildHealthEndpoint() throws {
        let url = try builder.buildProcessingURL(endpoint: .health)
        
        XCTAssertEqual(
            url.absoluteString,
            "https://example.com/api/health"
        )
    }
    
    func testURLComponentsWithSpaces() throws {
        // Test URL encoding with spaces
        let url = try builder.buildURL(
            path: "test", 
            parameters: ["param": "value with spaces"]
        )
        
        XCTAssertEqual(
            url.absoluteString,
            "https://example.com/api/test?param=value%20with%20spaces"
        )
    }
    
    func testURLComponentsWithSpecialCharacters() throws {
        // Test URL encoding with special characters
        let url = try builder.buildURL(
            path: "test", 
            parameters: ["param": "value+with&special=chars"]
        )
        
        // Check that the parameter is present and properly encoded
        // Different Swift versions may encode special characters differently
        // so we check that the special characters are encoded somehow
        XCTAssertTrue(url.absoluteString.hasPrefix("https://example.com/api/test?param="))
        XCTAssertFalse(url.absoluteString.contains("&special="), "& should be encoded")
        // Note: the = in the URL parameter itself is not encoded, only the = in the value
        XCTAssertTrue(url.absoluteString.contains("%3D"), "= should be encoded as %3D")
    }
}
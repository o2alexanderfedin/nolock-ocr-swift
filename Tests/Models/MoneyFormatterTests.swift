import XCTest
@testable import NolockOCR

final class MoneyFormatterTests: XCTestCase {
    
    // MARK: - Format Decimal Tests
    
    func testFormatDecimal() {
        let formatter = MoneyFormatter.shared
        
        // Create and verify a test formatter with the same config to compare results
        let testFormatter = NumberFormatter()
        testFormatter.minimumFractionDigits = 2
        testFormatter.maximumFractionDigits = 2
        testFormatter.numberStyle = .decimal
        
        // Test a set of sample values
        let testValues: [Decimal] = [100, 0, 12.34, 0.5, -99.99, -0.01]
        
        for value in testValues {
            let expectedResult = testFormatter.string(from: value as NSDecimalNumber)?.replacingOccurrences(of: testFormatter.groupingSeparator, with: "") ?? "\(value)"
            XCTAssertEqual(formatter.formatDecimal(value), expectedResult)
        }
    }
    
    // MARK: - Decimal From String Tests
    
    func testDecimalFromString() {
        let formatter = MoneyFormatter.shared
        
        // Test valid decimal strings that should work with Decimal(string:)
        XCTAssertEqual(formatter.decimalFromString("100"), Decimal(string: "100"))
        XCTAssertEqual(formatter.decimalFromString("12.34"), Decimal(string: "12.34"))
        XCTAssertEqual(formatter.decimalFromString("0.5"), Decimal(string: "0.5"))
        XCTAssertEqual(formatter.decimalFromString("-99.99"), Decimal(string: "-99.99"))
        
        // Test nil and empty strings
        XCTAssertNil(formatter.decimalFromString(nil))
        
        // Empty string behavior matches actual Decimal(string:) behavior
        XCTAssertEqual(formatter.decimalFromString(""), Decimal(string: ""))
        
        // Test invalid strings - behavior should match Decimal(string:)
        XCTAssertEqual(formatter.decimalFromString("abc"), Decimal(string: "abc"))
        XCTAssertEqual(formatter.decimalFromString("12.34.56"), Decimal(string: "12.34.56"))
        XCTAssertEqual(formatter.decimalFromString("$12.34"), Decimal(string: "$12.34"))
    }
    
    // MARK: - Decode Decimal Value Tests
    
    func testDecodeDecimalValue() throws {
        let formatter = MoneyFormatter.shared
        
        // Create test data directly using decoder
        let jsonString = """
        {
            "decimal_value": 123.45,
            "string_value": "67.89",
            "invalid_value": "abc",
            "null_value": null
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        // Decode directly to a wrapper that gives us access to the container
        struct CodingKeysWrapper: Decodable {
            enum CodingKeys: String, CodingKey {
                case decimalValue = "decimal_value"
                case stringValue = "string_value"
                case invalidValue = "invalid_value"
                case nullValue = "null_value"
            }
            
            let container: KeyedDecodingContainer<CodingKeys>
            
            init(from decoder: Decoder) throws {
                container = try decoder.container(keyedBy: CodingKeys.self)
            }
        }
        
        let wrapper = try decoder.decode(CodingKeysWrapper.self, from: jsonData)
        
        // Test decoding decimal and string representations
        let decimalValueFromDecimal = try formatter.decodeDecimalValue(
            from: wrapper.container,
            forKey: CodingKeysWrapper.CodingKeys.decimalValue
        )
        XCTAssertEqual(decimalValueFromDecimal, Decimal(123.45))
        
        let decimalValueFromString = try formatter.decodeDecimalValue(
            from: wrapper.container,
            forKey: CodingKeysWrapper.CodingKeys.stringValue
        )
        XCTAssertEqual(decimalValueFromString, Decimal(67.89))
        
        // Test handling invalid values
        let decimalValueFromInvalid = try formatter.decodeDecimalValue(
            from: wrapper.container,
            forKey: CodingKeysWrapper.CodingKeys.invalidValue
        )
        XCTAssertNil(decimalValueFromInvalid)
        
        let decimalValueFromNull = try formatter.decodeDecimalValue(
            from: wrapper.container,
            forKey: CodingKeysWrapper.CodingKeys.nullValue
        )
        XCTAssertNil(decimalValueFromNull)
    }
}
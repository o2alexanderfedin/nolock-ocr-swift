import XCTest
@testable import NolockOCR

final class SafeDecodableEnumTests: XCTestCase {
    
    // MARK: - Tests
    
    func testEnumDecoding() throws {
        // Test valid values
        XCTAssertEqual(try decode(json: "\"checking\"") as BankAccountType, .checking)
        XCTAssertEqual(try decode(json: "\"savings\"") as BankAccountType, .savings)
        XCTAssertEqual(try decode(json: "\"money_market\"") as BankAccountType, .moneyMarket)
        
        // Test unknown values (should return default)
        XCTAssertEqual(try decode(json: "\"unknown_value\"") as BankAccountType, .other)
        XCTAssertEqual(try decode(json: "\"invalid\"") as BankAccountType, .other)
    }
    
    func testDocumentTypeDecoding() throws {
        // Test valid values
        XCTAssertEqual(try decode(json: "\"check\"") as DocumentType, .check)
        XCTAssertEqual(try decode(json: "\"receipt\"") as DocumentType, .receipt)
        
        // Test unknown values (should return default)
        XCTAssertEqual(try decode(json: "\"unknown_type\"") as DocumentType, .auto)
    }
    
    func testMultipleEnumTypes() throws {
        // Test CheckType
        XCTAssertEqual(try decode(json: "\"personal\"") as CheckType, .personal)
        XCTAssertEqual(try decode(json: "\"business\"") as CheckType, .business)
        XCTAssertEqual(try decode(json: "\"unknown\"") as CheckType, .other)
        
        // Test PaymentMethod
        XCTAssertEqual(try decode(json: "\"credit\"") as PaymentMethod, .credit)
        XCTAssertEqual(try decode(json: "\"debit\"") as PaymentMethod, .debit)
        XCTAssertEqual(try decode(json: "\"unknown\"") as PaymentMethod, .other)
        
        // Test CardType
        XCTAssertEqual(try decode(json: "\"visa\"") as CardType, .visa)
        XCTAssertEqual(try decode(json: "\"mastercard\"") as CardType, .mastercard)
        XCTAssertEqual(try decode(json: "\"unknown\"") as CardType, .other)
        
        // Test TaxType
        XCTAssertEqual(try decode(json: "\"sales\"") as TaxType, .sales)
        XCTAssertEqual(try decode(json: "\"vat\"") as TaxType, .vat)
        XCTAssertEqual(try decode(json: "\"unknown\"") as TaxType, .other)
    }
    
    func testOverriddenTypeName() throws {
        // Create a test enum with an overridden typeName
        enum TestEnum: String, Codable, SafeDecodableEnum {
            case one
            case two
            case other
            
            static var defaultValue: TestEnum { .other }
            static var typeName: String { "CustomTypeName" }
        }
        
        // Test the default protocol implementation
        XCTAssertEqual(CheckType.typeName, "CheckType")
        
        // Test the overridden implementation
        XCTAssertEqual(TestEnum.typeName, "CustomTypeName")
    }
    
    func testDecodingEnumInComplexObject() throws {
        // Create test JSON for a complex object containing an enum
        let json = """
        {
            "account_type": "checking",
            "name": "Test Account",
            "balance": 100.50
        }
        """
        
        // Test decoding as part of a complex object
        struct TestAccount: Decodable {
            let accountType: BankAccountType
            let name: String
            let balance: Double
            
            enum CodingKeys: String, CodingKey {
                case accountType = "account_type"
                case name, balance
            }
        }
        
        let data = json.data(using: .utf8)!
        let account = try JSONDecoder().decode(TestAccount.self, from: data)
        
        XCTAssertEqual(account.accountType, .checking)
        XCTAssertEqual(account.name, "Test Account")
        XCTAssertEqual(account.balance, 100.50)
    }
    
    // MARK: - Helper Methods
    
    /// Helper method to decode a JSON string into a specified enum type
    private func decode<T: Decodable>(json: String) throws -> T {
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(T.self, from: data)
    }
}
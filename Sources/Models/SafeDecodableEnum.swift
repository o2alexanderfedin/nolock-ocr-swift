import Foundation

/// A protocol for enums that need safe decoding with fallback to a default value
/// This protocol standardizes the pattern of decoding string-based enums with a fallback case
public protocol SafeDecodableEnum: RawRepresentable, Decodable where RawValue == String {
    /// The default/fallback case to use when an unknown value is encountered
    static var defaultValue: Self { get }
    
    /// The name of the enum type, used for warning messages
    static var typeName: String { get }
}

/// Extension providing default implementations for SafeDecodableEnum
extension SafeDecodableEnum {
    /// Default implementation for the name of the enum type
    /// Uses the Swift type name by default, can be overridden if needed
    public static var typeName: String {
        return String(describing: Self.self)
    }
    
    /// A standard implementation of init(from:) that safely decodes an enum value
    /// and falls back to a default value if the raw value is not recognized
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        if let knownValue = Self(rawValue: rawValue) {
            self = knownValue
        } else {
            print("Warning: Unknown \(Self.typeName) value: '\(rawValue)', defaulting to .\(Self.defaultValue)")
            self = Self.defaultValue
        }
    }
}
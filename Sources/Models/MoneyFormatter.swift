import Foundation

/// Utility class for handling monetary values and decimal formatting
/// Used throughout the codebase for consistent formatting and parsing of currency values
public struct MoneyFormatter {
    
    /// Shared singleton instance for app-wide use
    public static let shared = MoneyFormatter()
    
    /// Currency formatter configured for standard monetary values with 2 decimal places
    private let formatter: NumberFormatter
    
    /// Private initializer to enforce singleton pattern
    private init() {
        formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
    }
    
    /// Formats a Decimal value as a string with 2 decimal places and no grouping separators
    /// - Parameter value: The Decimal value to format
    /// - Returns: A formatted string representation of the decimal value
    public func formatDecimal(_ value: Decimal) -> String {
        if let formattedValue = formatter.string(from: value as NSDecimalNumber) {
            return formattedValue.replacingOccurrences(of: formatter.groupingSeparator, with: "")
        } else {
            return "\(value)"
        }
    }
    
    /// Decodes a decimal value from a container, handling both string and decimal representations
    /// - Parameters:
    ///   - container: The keyed decoding container
    ///   - key: The coding key to decode from
    /// - Returns: A Decimal value if successful, nil otherwise
    public func decodeDecimalValue<T: CodingKey>(from container: KeyedDecodingContainer<T>, forKey key: T) throws -> Decimal? {
        if let decimalValue = try? container.decodeIfPresent(Decimal.self, forKey: key) {
            return decimalValue
        } else if let stringValue = try? container.decodeIfPresent(String.self, forKey: key),
                  let decimalFromString = Decimal(string: stringValue) {
            return decimalFromString
        }
        return nil
    }
    
    /// Converts a string representation of a monetary value to a Decimal
    /// - Parameter string: The string to convert
    /// - Returns: A Decimal value if the string is a valid representation, nil otherwise
    public func decimalFromString(_ string: String?) -> Decimal? {
        guard let string = string else { return nil }
        return Decimal(string: string)
    }
}
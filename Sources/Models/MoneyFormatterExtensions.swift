import Foundation

// MARK: - Extensions for models to use MoneyFormatter

// Extension for all decimal-formatting model types
public protocol MoneyFormattable {
    // This is an empty protocol to conform to
}

// Default implementation of formatDecimal for MoneyFormattable types
extension MoneyFormattable {
    /// Format a decimal value using the shared MoneyFormatter
    func formatDecimal(_ value: Decimal) -> String {
        return MoneyFormatter.shared.formatDecimal(value)
    }
}

// Making model types conform to MoneyFormattable
// Only adding conformance to types that don't already conform
extension Check: MoneyFormattable {}
import Foundation

/// Type of receipt
public enum ReceiptType: String, Codable {
    case sale
    case `return`
    case refund
    case estimate
    case proforma
    case utility
    case other
    
    // Add a fallback case for unknown values
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        if let knownValue = ReceiptType(rawValue: rawValue) {
            self = knownValue
        } else {
            print("Warning: Unknown ReceiptType value: \(rawValue), defaulting to .other")
            self = .other
        }
    }
}

/// Method of payment
public enum PaymentMethod: String, Codable {
    case credit
    case debit
    case cash
    case check
    case giftCard = "gift_card"
    case storeCredit = "store_credit"
    case mobilePayment = "mobile_payment"
    case other
    
    // Add a fallback case for unknown values
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        if let knownValue = PaymentMethod(rawValue: rawValue) {
            self = knownValue
        } else {
            print("Warning: Unknown PaymentMethod value: '\(rawValue)', defaulting to .other")
            self = .other
        }
    }
}

/// Type of payment card
public enum CardType: String, Codable {
    case visa
    case mastercard
    case amex
    case discover
    case dinersClub = "diners_club"
    case jcb
    case unionPay = "union_pay"
    case other
    
    // Add a fallback case for unknown values
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        if let knownValue = CardType(rawValue: rawValue) {
            self = knownValue
        } else {
            print("Warning: Unknown CardType value: '\(rawValue)', defaulting to .other")
            self = .other
        }
    }
}

/// Type of tax
public enum TaxType: String, Codable {
    case sales
    case vat
    case gst
    case pst
    case hst
    case excise
    case service
    case other
    
    // Add a fallback case for unknown values
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        if let knownValue = TaxType(rawValue: rawValue) {
            self = knownValue
        } else {
            print("Warning: Unknown TaxType value: '\(rawValue)', defaulting to .other")
            self = .other
        }
    }
}

/// Format type of receipt
public enum ReceiptFormat: String, Codable {
    case retail
    case restaurant
    case service
    case utility
    case transportation
    case accommodation
    case other
    
    // Add a fallback case for unknown values
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        if let knownValue = ReceiptFormat(rawValue: rawValue) {
            self = knownValue
        } else {
            print("Warning: Unknown ReceiptFormat value: '\(rawValue)', defaulting to .other")
            self = .other
        }
    }
}

/// Unit of measurement
public enum UnitOfMeasure: String, Codable {
    case ea
    case kg
    case g
    case lb
    case oz
    case l
    case ml
    case gal
    case pc
    case pr
    case pk
    case box
    case other
    
    // Add a fallback case for unknown values
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        if let knownValue = UnitOfMeasure(rawValue: rawValue) {
            self = knownValue
        } else {
            print("Warning: Unknown UnitOfMeasure value: '\(rawValue)', defaulting to .other")
            self = .other
        }
    }
}

/// Merchant information
public struct MerchantInfo: Codable {
    /// Name of the merchant or store
    public let name: String
    
    /// Physical address of the merchant
    public let address: String?
    
    /// Contact phone number
    public let phone: String?
    
    /// Website URL
    public let website: String?
    
    /// Tax identification number
    public let taxId: String?
    
    /// Store or branch identifier
    public let storeId: String?
    
    /// Name of the store chain if applicable
    public let chainName: String?
    
    /// Standard initializer for creating merchant info programmatically
    public init(
        name: String,
        address: String?,
        phone: String?,
        website: String?,
        taxId: String?,
        storeId: String?,
        chainName: String?
    ) {
        self.name = name
        self.address = address
        self.phone = phone
        self.website = website
        self.taxId = taxId
        self.storeId = storeId
        self.chainName = chainName
    }
}

/// Receipt totals information
public struct ReceiptTotals: Codable {
    /// Pre-tax total amount as Decimal for precise financial calculations
    public let subtotal: Decimal?
    
    /// Total tax amount as Decimal for precise financial calculations
    public let tax: Decimal?
    
    /// Tip/gratuity amount as Decimal for precise financial calculations
    public let tip: Decimal?
    
    /// Total discount amount as Decimal for precise financial calculations
    public let discount: Decimal?
    
    /// Final total amount as Decimal for precise financial calculations
    public let total: Decimal
    
    // Computed properties to access monetary values as formatted strings
    
    /// Pre-tax total amount as formatted string
    public var subtotalString: String? {
        guard let subtotal = subtotal else { return nil }
        return formatDecimal(subtotal)
    }
    
    /// Total tax amount as formatted string
    public var taxString: String? {
        guard let tax = tax else { return nil }
        return formatDecimal(tax)
    }
    
    /// Tip/gratuity amount as formatted string
    public var tipString: String? {
        guard let tip = tip else { return nil }
        return formatDecimal(tip)
    }
    
    /// Total discount amount as formatted string
    public var discountString: String? {
        guard let discount = discount else { return nil }
        return formatDecimal(discount)
    }
    
    /// Final total amount as formatted string
    public var totalString: String {
        return formatDecimal(total)
    }
    
    /// Helper function to format a Decimal value as a string
    private func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        
        if let formattedValue = formatter.string(from: value as NSDecimalNumber) {
            return formattedValue.replacingOccurrences(of: formatter.groupingSeparator, with: "")
        } else {
            return "\(value)"
        }
    }
    
    /// Standard initializer for creating receipt totals programmatically
    public init(
        subtotal: Decimal?,
        tax: Decimal?,
        tip: Decimal?,
        discount: Decimal?,
        total: Decimal
    ) {
        self.subtotal = subtotal
        self.tax = tax
        self.tip = tip
        self.discount = discount
        self.total = total
    }
    
    /// Alternative initializer for creating receipt totals from string values
    public init(
        subtotalString: String?,
        taxString: String?,
        tipString: String?,
        discountString: String?,
        totalString: String
    ) throws {
        let subtotalDecimal = subtotalString.flatMap { Decimal(string: $0) }
        let taxDecimal = taxString.flatMap { Decimal(string: $0) }
        let tipDecimal = tipString.flatMap { Decimal(string: $0) }
        let discountDecimal = discountString.flatMap { Decimal(string: $0) }
        
        guard let totalDecimal = Decimal(string: totalString) else {
            // Create a simple error since we're not in a decoder context
            let error = NSError(
                domain: "ReceiptTotals",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Total string must be a valid decimal number"]
            )
            throw error
        }
        
        self.init(
            subtotal: subtotalDecimal,
            tax: taxDecimal,
            tip: tipDecimal,
            discount: discountDecimal,
            total: totalDecimal
        )
    }
    
    /// Custom decoding to handle both string and numeric values
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Helper function to decode a monetary value that could be a string or decimal
        func decodeDecimalValue(forKey key: CodingKeys) throws -> Decimal? {
            if let decimalValue = try? container.decodeIfPresent(Decimal.self, forKey: key) {
                return decimalValue
            } else if let stringValue = try? container.decodeIfPresent(String.self, forKey: key), 
                      let decimalFromString = Decimal(string: stringValue) {
                return decimalFromString
            }
            return nil
        }
        
        // Decode optional fields
        subtotal = try decodeDecimalValue(forKey: .subtotal)
        tax = try decodeDecimalValue(forKey: .tax)
        tip = try decodeDecimalValue(forKey: .tip)
        discount = try decodeDecimalValue(forKey: .discount)
        
        // Decode required total field
        if let totalDecimal = try? container.decode(Decimal.self, forKey: .total) {
            total = totalDecimal
        } else if let totalString = try? container.decode(String.self, forKey: .total),
                  let totalDecimal = Decimal(string: totalString) {
            total = totalDecimal
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .total,
                in: container,
                debugDescription: "Total must be either a string or a decimal number"
            )
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case subtotal, tax, tip, discount, total
    }
    
    /// Custom encoding to ensure proper handling of Decimal values
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode all fields
        try container.encodeIfPresent(subtotal, forKey: .subtotal)
        try container.encodeIfPresent(tax, forKey: .tax)
        try container.encodeIfPresent(tip, forKey: .tip)
        try container.encodeIfPresent(discount, forKey: .discount)
        try container.encode(total, forKey: .total)
    }
}

/// Line item on the receipt
public struct ReceiptLineItem: Codable {
    /// Item description or name
    public let description: String
    
    /// Stock keeping unit or product code
    public let sku: String?
    
    /// Quantity purchased
    public let quantity: Double?
    
    /// Unit of measurement
    public let unit: String?
    
    /// Price per unit as Decimal for precise financial calculations
    public let unitPrice: Decimal?
    
    /// Total price for this line item as Decimal for precise financial calculations
    public let totalPrice: Decimal
    
    /// Whether the item was discounted
    public let discounted: Bool?
    
    /// Amount of discount applied as Decimal for precise financial calculations
    public let discountAmount: Decimal?
    
    /// Product category
    public let category: String?
    
    // Computed properties to access monetary values as formatted strings
    
    /// Price per unit as formatted string
    public var unitPriceString: String? {
        guard let unitPrice = unitPrice else { return nil }
        return formatDecimal(unitPrice)
    }
    
    /// Total price for this line item as formatted string
    public var totalPriceString: String {
        return formatDecimal(totalPrice)
    }
    
    /// Amount of discount applied as formatted string
    public var discountAmountString: String? {
        guard let discountAmount = discountAmount else { return nil }
        return formatDecimal(discountAmount)
    }
    
    /// Helper function to format a Decimal value as a string
    private func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        
        if let formattedValue = formatter.string(from: value as NSDecimalNumber) {
            return formattedValue.replacingOccurrences(of: formatter.groupingSeparator, with: "")
        } else {
            return "\(value)"
        }
    }
    
    /// Standard initializer for creating line items programmatically
    public init(
        description: String,
        sku: String?,
        quantity: Double?,
        unit: String?,
        unitPrice: Decimal?,
        totalPrice: Decimal,
        discounted: Bool?,
        discountAmount: Decimal?,
        category: String?
    ) {
        self.description = description
        self.sku = sku
        self.quantity = quantity
        self.unit = unit
        self.unitPrice = unitPrice
        self.totalPrice = totalPrice
        self.discounted = discounted
        self.discountAmount = discountAmount
        self.category = category
    }
    
    /// Alternative initializer for creating line items from string values
    public init(
        description: String,
        sku: String?,
        quantity: Double?,
        unit: String?,
        unitPriceString: String?,
        totalPriceString: String,
        discounted: Bool?,
        discountAmountString: String?,
        category: String?
    ) throws {
        let unitPriceDecimal = unitPriceString.flatMap { Decimal(string: $0) }
        let discountAmountDecimal = discountAmountString.flatMap { Decimal(string: $0) }
        
        guard let totalPriceDecimal = Decimal(string: totalPriceString) else {
            // Create a simple error since we're not in a decoder context
            let error = NSError(
                domain: "ReceiptLineItem",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Total price string must be a valid decimal number"]
            )
            throw error
        }
        
        self.init(
            description: description,
            sku: sku,
            quantity: quantity,
            unit: unit,
            unitPrice: unitPriceDecimal,
            totalPrice: totalPriceDecimal,
            discounted: discounted,
            discountAmount: discountAmountDecimal,
            category: category
        )
    }
    
    /// Custom decoding to handle both string and numeric values
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Helper function to decode a monetary value that could be a string or decimal
        func decodeDecimalValue(forKey key: CodingKeys) throws -> Decimal? {
            if let decimalValue = try? container.decodeIfPresent(Decimal.self, forKey: key) {
                return decimalValue
            } else if let stringValue = try? container.decodeIfPresent(String.self, forKey: key),
                      let decimalFromString = Decimal(string: stringValue) {
                return decimalFromString
            }
            return nil
        }
        
        // Decode required fields
        description = try container.decode(String.self, forKey: .description)
        
        // Decode optional fields
        sku = try container.decodeIfPresent(String.self, forKey: .sku)
        quantity = try container.decodeIfPresent(Double.self, forKey: .quantity)
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        discounted = try container.decodeIfPresent(Bool.self, forKey: .discounted)
        
        // Decode monetary fields as Decimal
        unitPrice = try decodeDecimalValue(forKey: .unitPrice)
        discountAmount = try decodeDecimalValue(forKey: .discountAmount)
        
        // Decode required totalPrice field
        if let totalPriceDecimal = try? container.decode(Decimal.self, forKey: .totalPrice) {
            totalPrice = totalPriceDecimal
        } else if let totalPriceString = try? container.decode(String.self, forKey: .totalPrice),
                  let totalPriceDecimal = Decimal(string: totalPriceString) {
            totalPrice = totalPriceDecimal
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .totalPrice,
                in: container,
                debugDescription: "Total price must be either a string or a decimal number"
            )
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case description, sku, quantity, unit, unitPrice, totalPrice
        case discounted, discountAmount, category
    }
    
    /// Custom encoding to ensure proper handling of Decimal values
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode all fields
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(sku, forKey: .sku)
        try container.encodeIfPresent(quantity, forKey: .quantity)
        try container.encodeIfPresent(unit, forKey: .unit)
        try container.encodeIfPresent(unitPrice, forKey: .unitPrice)
        try container.encode(totalPrice, forKey: .totalPrice)
        try container.encodeIfPresent(discounted, forKey: .discounted)
        try container.encodeIfPresent(discountAmount, forKey: .discountAmount)
        try container.encodeIfPresent(category, forKey: .category)
    }
}

/// Tax item on a receipt
public struct ReceiptTaxItem: Codable {
    /// Name of tax (e.g., 'VAT', 'Sales Tax')
    public let taxName: String
    
    /// Type of tax
    public let taxType: String?
    
    /// Tax rate as Decimal (e.g., 0.1 for 10%)
    public let taxRate: Decimal?
    
    /// Tax amount as Decimal for precise financial calculations
    public let taxAmount: Decimal
    
    // Computed properties to access monetary values as formatted strings
    
    /// Tax rate as formatted string
    public var taxRateString: String? {
        guard let taxRate = taxRate else { return nil }
        return formatDecimal(taxRate)
    }
    
    /// Tax amount as formatted string
    public var taxAmountString: String {
        return formatDecimal(taxAmount)
    }
    
    /// Helper function to format a Decimal value as a string
    private func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        
        if let formattedValue = formatter.string(from: value as NSDecimalNumber) {
            return formattedValue.replacingOccurrences(of: formatter.groupingSeparator, with: "")
        } else {
            return "\(value)"
        }
    }
    
    /// Standard initializer for creating tax items programmatically
    public init(
        taxName: String,
        taxType: String?,
        taxRate: Decimal?,
        taxAmount: Decimal
    ) {
        self.taxName = taxName
        self.taxType = taxType
        self.taxRate = taxRate
        self.taxAmount = taxAmount
    }
    
    /// Alternative initializer for creating tax items from string values
    public init(
        taxName: String,
        taxType: String?,
        taxRateString: String?,
        taxAmountString: String
    ) throws {
        let taxRateDecimal = taxRateString.flatMap { Decimal(string: $0) }
        
        guard let taxAmountDecimal = Decimal(string: taxAmountString) else {
            // Create a simple error since we're not in a decoder context
            let error = NSError(
                domain: "ReceiptTaxItem",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Tax amount string must be a valid decimal number"]
            )
            throw error
        }
        
        self.init(
            taxName: taxName,
            taxType: taxType,
            taxRate: taxRateDecimal,
            taxAmount: taxAmountDecimal
        )
    }
    
    /// Custom decoding to handle both string and numeric values
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Helper function to decode a monetary value that could be a string or decimal
        func decodeDecimalValue(forKey key: CodingKeys) throws -> Decimal? {
            if let decimalValue = try? container.decodeIfPresent(Decimal.self, forKey: key) {
                return decimalValue
            } else if let stringValue = try? container.decodeIfPresent(String.self, forKey: key),
                      let decimalFromString = Decimal(string: stringValue) {
                return decimalFromString
            }
            return nil
        }
        
        // Decode required fields
        taxName = try container.decode(String.self, forKey: .taxName)
        
        // Decode optional fields
        taxType = try container.decodeIfPresent(String.self, forKey: .taxType)
        
        // Decode tax rate which could be a string or decimal
        taxRate = try decodeDecimalValue(forKey: .taxRate)
        
        // Decode required taxAmount field
        if let taxAmountDecimal = try? container.decode(Decimal.self, forKey: .taxAmount) {
            taxAmount = taxAmountDecimal
        } else if let taxAmountString = try? container.decode(String.self, forKey: .taxAmount),
                  let taxAmountDecimal = Decimal(string: taxAmountString) {
            taxAmount = taxAmountDecimal
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .taxAmount,
                in: container, 
                debugDescription: "Tax amount must be either a string or a decimal number"
            )
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case taxName, taxType, taxRate, taxAmount
    }
    
    /// Custom encoding to ensure proper handling of Decimal values
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode all fields
        try container.encode(taxName, forKey: .taxName)
        try container.encodeIfPresent(taxType, forKey: .taxType)
        try container.encodeIfPresent(taxRate, forKey: .taxRate)
        try container.encode(taxAmount, forKey: .taxAmount)
    }
}

/// Payment method used on a receipt
public struct ReceiptPaymentMethod: Codable {
    /// Method of payment
    public let method: PaymentMethod
    
    /// Type of card
    public let cardType: String?
    
    /// Last 4 digits of payment card
    public let lastDigits: String?
    
    /// Amount paid with this method as Decimal for precise financial calculations
    public let amount: Decimal
    
    /// Payment transaction ID
    public let transactionId: String?
    
    // Computed property to access amount as a formatted string
    
    /// Amount paid with this method as a formatted string
    public var amountString: String {
        return formatDecimal(amount)
    }
    
    /// Helper function to format a Decimal value as a string
    private func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        
        if let formattedValue = formatter.string(from: value as NSDecimalNumber) {
            return formattedValue.replacingOccurrences(of: formatter.groupingSeparator, with: "")
        } else {
            return "\(value)"
        }
    }
    
    /// Standard initializer for creating payment methods programmatically
    public init(
        method: PaymentMethod,
        cardType: String?,
        lastDigits: String?,
        amount: Decimal,
        transactionId: String?
    ) {
        self.method = method
        self.cardType = cardType
        self.lastDigits = lastDigits
        self.amount = amount
        self.transactionId = transactionId
    }
    
    /// Alternative initializer for creating payment methods from string values
    public init(
        method: PaymentMethod,
        cardType: String?,
        lastDigits: String?,
        amountString: String,
        transactionId: String?
    ) throws {
        guard let amountDecimal = Decimal(string: amountString) else {
            // Create a simple error since we're not in a decoder context
            let error = NSError(
                domain: "ReceiptPaymentMethod",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Amount string must be a valid decimal number"]
            )
            throw error
        }
        
        self.init(
            method: method,
            cardType: cardType,
            lastDigits: lastDigits,
            amount: amountDecimal,
            transactionId: transactionId
        )
    }
    
    /// Custom decoding to handle both string and numeric values
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode required fields
        method = try container.decode(PaymentMethod.self, forKey: .method)
        
        // Decode optional fields
        cardType = try container.decodeIfPresent(String.self, forKey: .cardType)
        lastDigits = try container.decodeIfPresent(String.self, forKey: .lastDigits)
        transactionId = try container.decodeIfPresent(String.self, forKey: .transactionId)
        
        // Decode required amount field
        if let amountDecimal = try? container.decode(Decimal.self, forKey: .amount) {
            amount = amountDecimal
        } else if let amountString = try? container.decode(String.self, forKey: .amount),
                  let amountDecimal = Decimal(string: amountString) {
            amount = amountDecimal
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .amount,
                in: container,
                debugDescription: "Amount must be either a string or a decimal number"
            )
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case method, cardType, lastDigits, amount, transactionId
    }
    
    /// Custom encoding to ensure proper handling of Decimal values
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode all fields
        try container.encode(method, forKey: .method)
        try container.encodeIfPresent(cardType, forKey: .cardType)
        try container.encodeIfPresent(lastDigits, forKey: .lastDigits)
        try container.encode(amount, forKey: .amount)
        try container.encodeIfPresent(transactionId, forKey: .transactionId)
    }
}

/// Receipt metadata information
public struct ReceiptMetadata: Codable {
    /// Overall confidence of extraction (0-1)
    public let confidenceScore: Double
    
    /// ISO currency code detected
    public let currency: String?
    
    /// ISO language code of the receipt
    public let languageCode: String?
    
    /// Time zone identifier
    public let timeZone: String?
    
    /// Format type of receipt
    public let receiptFormat: ReceiptFormat?
    
    /// Reference to the source image
    public let sourceImageId: String?
    
    /// List of warning messages
    public let warnings: [String]?
    
    /// Standard initializer for creating receipt metadata programmatically
    public init(
        confidenceScore: Double,
        currency: String?,
        languageCode: String?,
        timeZone: String?,
        receiptFormat: ReceiptFormat?,
        sourceImageId: String?,
        warnings: [String]?
    ) {
        self.confidenceScore = confidenceScore
        self.currency = currency
        self.languageCode = languageCode
        self.timeZone = timeZone
        self.receiptFormat = receiptFormat
        self.sourceImageId = sourceImageId
        self.warnings = warnings
    }
}

/// Receipt data extracted from an image
public struct Receipt: Codable {
    /// Merchant information
    public let merchant: MerchantInfo
    
    /// Receipt or invoice number
    public let receiptNumber: String?
    
    /// Type of receipt
    public let receiptType: ReceiptType?
    
    /// Date and time of transaction (ISO 8601 format) as string
    public let timestamp: String
    
    /// Computed property to access timestamp as Date object
    public var timestampDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: timestamp)
    }
    
    /// Method of payment
    public let paymentMethod: String?
    
    /// Totals information
    public let totals: ReceiptTotals
    
    /// 3-letter ISO currency code
    public let currency: String
    
    /// List of line items on the receipt
    public let items: [ReceiptLineItem]?
    
    /// Breakdown of taxes
    public let taxes: [ReceiptTaxItem]?
    
    /// Details about payment methods used
    public let payments: [ReceiptPaymentMethod]?
    
    /// Additional notes or comments
    public let notes: [String]?
    
    /// Metadata about the receipt extraction
    public let metadata: ReceiptMetadata?
    
    /// Confidence score for the receipt overall
    public let confidence: Double
    
    /// Standard initializer for creating receipts programmatically
    public init(
        merchant: MerchantInfo,
        receiptNumber: String?,
        receiptType: ReceiptType?,
        timestamp: String,
        paymentMethod: String?,
        totals: ReceiptTotals,
        currency: String,
        items: [ReceiptLineItem]?,
        taxes: [ReceiptTaxItem]?,
        payments: [ReceiptPaymentMethod]?,
        notes: [String]?,
        metadata: ReceiptMetadata?,
        confidence: Double
    ) {
        self.merchant = merchant
        self.receiptNumber = receiptNumber
        self.receiptType = receiptType
        self.timestamp = timestamp
        self.paymentMethod = paymentMethod
        self.totals = totals
        self.currency = currency
        self.items = items
        self.taxes = taxes
        self.payments = payments
        self.notes = notes
        self.metadata = metadata
        self.confidence = confidence
    }
}

/// Receipt processing response
public struct ReceiptResponse: Codable {
    /// Extracted receipt data
    public let data: Receipt
    
    /// Confidence scores for processing
    public let confidence: Confidence
}
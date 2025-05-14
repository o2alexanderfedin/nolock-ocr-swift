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
    /// Pre-tax total amount as string to preserve exact decimal representation
    public let subtotal: String?
    
    /// Total tax amount as string to preserve exact decimal representation
    public let tax: String?
    
    /// Tip/gratuity amount as string to preserve exact decimal representation
    public let tip: String?
    
    /// Total discount amount as string to preserve exact decimal representation
    public let discount: String?
    
    /// Final total amount as string to preserve exact decimal representation
    public let total: String
    
    // Computed properties to access monetary values as Decimal
    
    /// Pre-tax total amount as Decimal
    public var subtotalDecimal: Decimal? {
        guard let subtotal = subtotal else { return nil }
        return Decimal(string: subtotal)
    }
    
    /// Total tax amount as Decimal
    public var taxDecimal: Decimal? {
        guard let tax = tax else { return nil }
        return Decimal(string: tax)
    }
    
    /// Tip/gratuity amount as Decimal
    public var tipDecimal: Decimal? {
        guard let tip = tip else { return nil }
        return Decimal(string: tip)
    }
    
    /// Total discount amount as Decimal
    public var discountDecimal: Decimal? {
        guard let discount = discount else { return nil }
        return Decimal(string: discount)
    }
    
    /// Final total amount as Decimal
    public var totalDecimal: Decimal? {
        return Decimal(string: total)
    }
    
    /// Standard initializer for creating receipt totals programmatically
    public init(
        subtotal: String?,
        tax: String?,
        tip: String?,
        discount: String?,
        total: String
    ) {
        self.subtotal = subtotal
        self.tax = tax
        self.tip = tip
        self.discount = discount
        self.total = total
    }
    
    /// Custom decoding to handle both string and numeric values
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Helper function to decode a monetary value that could be a string or number
        func decodeMonetaryValue(forKey key: CodingKeys) throws -> String? {
            if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
                return stringValue
            } else if let doubleValue = try? container.decode(Double.self, forKey: key) {
                return String(format: "%.2f", doubleValue)
            }
            return nil
        }
        
        // Decode optional fields
        subtotal = try decodeMonetaryValue(forKey: .subtotal)
        tax = try decodeMonetaryValue(forKey: .tax)
        tip = try decodeMonetaryValue(forKey: .tip)
        discount = try decodeMonetaryValue(forKey: .discount)
        
        // Decode required total field
        if let totalString = try? container.decode(String.self, forKey: .total) {
            total = totalString
        } else if let totalDouble = try? container.decode(Double.self, forKey: .total) {
            total = String(format: "%.2f", totalDouble)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .total,
                in: container,
                debugDescription: "Total must be either a string or a number"
            )
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case subtotal, tax, tip, discount, total
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
    
    /// Price per unit as string to preserve exact decimal representation
    public let unitPrice: String?
    
    /// Total price for this line item as string to preserve exact decimal representation
    public let totalPrice: String
    
    /// Whether the item was discounted
    public let discounted: Bool?
    
    /// Amount of discount applied as string to preserve exact decimal representation
    public let discountAmount: String?
    
    /// Product category
    public let category: String?
    
    // Computed properties to access monetary values as Decimal
    
    /// Price per unit as Decimal
    public var unitPriceDecimal: Decimal? {
        guard let unitPrice = unitPrice else { return nil }
        return Decimal(string: unitPrice)
    }
    
    /// Total price for this line item as Decimal
    public var totalPriceDecimal: Decimal? {
        return Decimal(string: totalPrice)
    }
    
    /// Amount of discount applied as Decimal
    public var discountAmountDecimal: Decimal? {
        guard let discountAmount = discountAmount else { return nil }
        return Decimal(string: discountAmount)
    }
    
    /// Standard initializer for creating line items programmatically
    public init(
        description: String,
        sku: String?,
        quantity: Double?,
        unit: String?,
        unitPrice: String?,
        totalPrice: String,
        discounted: Bool?,
        discountAmount: String?,
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
    
    /// Custom decoding to handle both string and numeric values
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Helper function to decode a monetary value that could be a string or number
        func decodeMonetaryValue(forKey key: CodingKeys) throws -> String? {
            if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
                return stringValue
            } else if let doubleValue = try? container.decode(Double.self, forKey: key) {
                return String(format: "%.2f", doubleValue)
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
        
        // Decode monetary fields that could be string or number
        unitPrice = try decodeMonetaryValue(forKey: .unitPrice)
        discountAmount = try decodeMonetaryValue(forKey: .discountAmount)
        
        // Decode required totalPrice field
        if let totalPriceString = try? container.decode(String.self, forKey: .totalPrice) {
            totalPrice = totalPriceString
        } else if let totalPriceDouble = try? container.decode(Double.self, forKey: .totalPrice) {
            totalPrice = String(format: "%.2f", totalPriceDouble)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .totalPrice,
                in: container,
                debugDescription: "Total price must be either a string or a number"
            )
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case description, sku, quantity, unit, unitPrice, totalPrice
        case discounted, discountAmount, category
    }
}

/// Tax item on a receipt
public struct ReceiptTaxItem: Codable {
    /// Name of tax (e.g., 'VAT', 'Sales Tax')
    public let taxName: String
    
    /// Type of tax
    public let taxType: String?
    
    /// Tax rate as string (e.g., "0.1" for 10%)
    public let taxRate: String?
    
    /// Tax amount as string to preserve exact decimal representation
    public let taxAmount: String
    
    // Computed properties to access monetary values as Decimal
    
    /// Tax rate as Decimal
    public var taxRateDecimal: Decimal? {
        guard let taxRate = taxRate else { return nil }
        return Decimal(string: taxRate)
    }
    
    /// Tax amount as Decimal
    public var taxAmountDecimal: Decimal? {
        return Decimal(string: taxAmount)
    }
    
    /// Standard initializer for creating tax items programmatically
    public init(
        taxName: String,
        taxType: String?,
        taxRate: String?,
        taxAmount: String
    ) {
        self.taxName = taxName
        self.taxType = taxType
        self.taxRate = taxRate
        self.taxAmount = taxAmount
    }
    
    /// Custom decoding to handle both string and numeric values
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Helper function to decode a monetary value that could be a string or number
        func decodeMonetaryValue(forKey key: CodingKeys) throws -> String? {
            if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
                return stringValue
            } else if let doubleValue = try? container.decode(Double.self, forKey: key) {
                return String(format: "%.2f", doubleValue)
            }
            return nil
        }
        
        // Decode required fields
        taxName = try container.decode(String.self, forKey: .taxName)
        
        // Decode optional fields
        taxType = try container.decodeIfPresent(String.self, forKey: .taxType)
        
        // Decode tax rate which could be a string or number
        taxRate = try decodeMonetaryValue(forKey: .taxRate)
        
        // Decode required taxAmount field
        if let taxAmountString = try? container.decode(String.self, forKey: .taxAmount) {
            taxAmount = taxAmountString
        } else if let taxAmountDouble = try? container.decode(Double.self, forKey: .taxAmount) {
            taxAmount = String(format: "%.2f", taxAmountDouble)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .taxAmount,
                in: container, 
                debugDescription: "Tax amount must be either a string or a number"
            )
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case taxName, taxType, taxRate, taxAmount
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
    
    /// Amount paid with this method as string to preserve exact decimal representation
    public let amount: String
    
    /// Payment transaction ID
    public let transactionId: String?
    
    // Computed property to access amount as Decimal
    
    /// Amount paid with this method as Decimal
    public var amountDecimal: Decimal? {
        return Decimal(string: amount)
    }
    
    /// Standard initializer for creating payment methods programmatically
    public init(
        method: PaymentMethod,
        cardType: String?,
        lastDigits: String?,
        amount: String,
        transactionId: String?
    ) {
        self.method = method
        self.cardType = cardType
        self.lastDigits = lastDigits
        self.amount = amount
        self.transactionId = transactionId
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
        if let amountString = try? container.decode(String.self, forKey: .amount) {
            amount = amountString
        } else if let amountDouble = try? container.decode(Double.self, forKey: .amount) {
            amount = String(format: "%.2f", amountDouble)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .amount,
                in: container,
                debugDescription: "Amount must be either a string or a number"
            )
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case method, cardType, lastDigits, amount, transactionId
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
import Foundation

/// Type of check
public enum CheckType: String, Codable {
    case personal
    case business
    case cashier
    case certified
    case traveler
    case government
    case payroll
    case moneyOrder = "money_order"
    case other
    
    // Add a fallback case for unknown values
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        if let knownValue = CheckType(rawValue: rawValue) {
            self = knownValue
        } else {
            print("Warning: Unknown CheckType value: '\(rawValue)', defaulting to .other")
            self = .other
        }
    }
}

/// Type of bank account
public enum BankAccountType: String, Codable {
    case checking
    case savings
    case moneyMarket = "money_market"
    case other
    
    // Add a fallback case for unknown values
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        if let knownValue = BankAccountType(rawValue: rawValue) {
            self = knownValue
        } else {
            print("Warning: Unknown BankAccountType value: '\(rawValue)', defaulting to .other")
            self = .other
        }
    }
}

/// Check metadata with confidence and source information
public struct CheckMetadata: Codable {
    /// Overall confidence of extraction (0-1)
    public let confidenceScore: Double
    
    /// Reference to the source image
    public let sourceImageId: String?
    
    /// Provider used for OCR
    public let ocrProvider: String?
    
    /// List of warning messages
    public let warnings: [String]?
}

/// Check data extracted from an image
public struct Check: Codable {
    /// Check number or identifier
    public let checkNumber: String
    
    /// Date on the check (ISO 8601 format) as string
    public let date: String
    
    /// Computed property to access date as Date object
    public var dateValue: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: date)
    }
    
    /// Person or entity to whom the check is payable
    public let payee: String
    
    /// Person or entity who wrote/signed the check
    public let payer: String?
    
    /// Dollar amount of the check as a string to preserve exact decimal representation
    public let amount: String
    
    /// Computed property to access amount as Decimal
    public var amountDecimal: Decimal? {
        return Decimal(string: amount)
    }
    
    /// Standard initializer for creating checks programmatically
    public init(
        checkNumber: String,
        date: String,
        payee: String,
        payer: String?,
        amount: String,
        amountText: String?,
        memo: String?,
        bankName: String?,
        routingNumber: String?,
        accountNumber: String?,
        checkType: CheckType?,
        accountType: BankAccountType?,
        signature: Bool?,
        signatureText: String?,
        fractionalCode: String?,
        micrLine: String?,
        metadata: CheckMetadata?,
        confidence: Double
    ) {
        self.checkNumber = checkNumber
        self.date = date
        self.payee = payee
        self.payer = payer
        self.amount = amount
        self.amountText = amountText
        self.memo = memo
        self.bankName = bankName
        self.routingNumber = routingNumber
        self.accountNumber = accountNumber
        self.checkType = checkType
        self.accountType = accountType
        self.signature = signature
        self.signatureText = signatureText
        self.fractionalCode = fractionalCode
        self.micrLine = micrLine
        self.metadata = metadata
        self.confidence = confidence
    }
    
    /// Custom decoding to handle both string and numeric amount values
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode required fields
        checkNumber = try container.decode(String.self, forKey: .checkNumber)
        date = try container.decode(String.self, forKey: .date)
        payee = try container.decode(String.self, forKey: .payee)
        
        // Handle optional fields
        payer = try container.decodeIfPresent(String.self, forKey: .payer)
        amountText = try container.decodeIfPresent(String.self, forKey: .amountText)
        memo = try container.decodeIfPresent(String.self, forKey: .memo)
        bankName = try container.decodeIfPresent(String.self, forKey: .bankName)
        routingNumber = try container.decodeIfPresent(String.self, forKey: .routingNumber)
        accountNumber = try container.decodeIfPresent(String.self, forKey: .accountNumber)
        checkType = try container.decodeIfPresent(CheckType.self, forKey: .checkType)
        accountType = try container.decodeIfPresent(BankAccountType.self, forKey: .accountType)
        signature = try container.decodeIfPresent(Bool.self, forKey: .signature)
        signatureText = try container.decodeIfPresent(String.self, forKey: .signatureText)
        fractionalCode = try container.decodeIfPresent(String.self, forKey: .fractionalCode)
        micrLine = try container.decodeIfPresent(String.self, forKey: .micrLine)
        metadata = try container.decodeIfPresent(CheckMetadata.self, forKey: .metadata)
        confidence = try container.decode(Double.self, forKey: .confidence)
        
        // Handle amount field that can be either string or Decimal
        if let amountString = try? container.decode(String.self, forKey: .amount) {
            // If it's already a string, use it directly
            amount = amountString
        } else if let amountDecimal = try? container.decode(Decimal.self, forKey: .amount) {
            // If it's a decimal number, convert to string with proper formatting
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            formatter.numberStyle = .decimal
            
            if let formattedAmount = formatter.string(from: amountDecimal as NSDecimalNumber) {
                amount = formattedAmount.replacingOccurrences(of: formatter.groupingSeparator, with: "")
            } else {
                amount = "\(amountDecimal)"
            }
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .amount,
                in: container,
                debugDescription: "Amount must be either a string or a decimal number"
            )
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case checkNumber, date, payee, payer, amount, amountText, memo, bankName
        case routingNumber, accountNumber, checkType, accountType, signature, signatureText
        case fractionalCode, micrLine, metadata, confidence
    }
    
    /// Written text amount of the check
    public let amountText: String?
    
    /// Memo or note on the check
    public let memo: String?
    
    /// Name of the bank issuing the check
    public let bankName: String?
    
    /// Bank routing number (9 digits)
    public let routingNumber: String?
    
    /// Bank account number
    public let accountNumber: String?
    
    /// Type of check
    public let checkType: CheckType?
    
    /// Type of bank account
    public let accountType: BankAccountType?
    
    /// Whether the check appears to be signed
    public let signature: Bool?
    
    /// Text of the signature if readable
    public let signatureText: String?
    
    /// Fractional code on the check
    public let fractionalCode: String?
    
    /// MICR line on the bottom of the check
    public let micrLine: String?
    
    /// Metadata about the check extraction
    public let metadata: CheckMetadata?
    
    /// Confidence score for the check overall
    public let confidence: Double
}

/// Check processing response
public struct CheckResponse: Codable {
    /// Extracted check data
    public let data: Check
    
    /// Confidence scores for processing
    public let confidence: Confidence
}
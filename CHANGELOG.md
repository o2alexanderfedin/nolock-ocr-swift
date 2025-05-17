# Changelog

All notable changes to the NolockOCR Swift package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Changed model representations to store monetary values as Decimal types directly instead of strings
- Updated Check and Receipt models to use Decimal for all amounts, prices, totals, and tax values
- Added convenience initializers for backward compatibility with string values
- Preserved string formatting capabilities through computed properties
- Made all monetary and total fields optional (amount, total, totalPrice, taxAmount, etc.)
- Updated decoders, encoders, and initializers to handle optional monetary values
- Added null-safety in string formatting computed properties for all optional monetary fields

## [1.3.1] - 2025-05-17

### Fixed
- Replaced Double with Decimal type for all monetary value decoding, improving precision for financial calculations
- Updated JSON decoders to use Decimal instead of Double for amounts, prices, totals and tax values
- Fixed number formatting to ensure consistent decimal places in monetary values

## [1.3.0] - 2025-05-13

### Added
- Task cancellation support for all asynchronous operations
- New OCRClientError enum with taskCancelled and noActiveTask cases
- cancelProcessing() method to cancel in-progress tasks
- Updated documentation with cancellation examples

## [1.2.0] - 2025-05-06

### Added
- Comprehensive Swift submodule guide with detailed usage instructions
- Documentation for Swift package integration and configuration
- Test integration guide for Swift submodules

### Changed 
- Improved HEIC image conversion to use PNG format instead of JPEG for better quality
- Updated Content-Type headers to reflect PNG image format
- Removed compression quality settings as PNG is a lossless format

## [1.0.0] - 2025-05-06

### Added
- Initial release of the NolockOCR Swift package
- Support for modern Swift concurrency (async/await)
- Support for traditional completion handlers for backward compatibility
- Type-safe models for check and receipt data
- Comprehensive error handling
- Environment configuration (development, staging, production)
- Support for HEIC image format with automatic conversion
- Confidence scoring for OCR and extraction quality
- Health check API
- Comprehensive documentation
- Example application demonstrating all features
- SwiftUI integration examples
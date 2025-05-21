# Changelog

All notable changes to the NolockOCR Swift package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.5.0] - 2025-05-21

### Added
- Added MoneyFormatter utility for standardized decimal handling
- Added EndpointBuilder for consistent URL construction
- Added SafeDecodableEnum protocol for standardized enum fallback behavior
- Added ImageProcessor service for centralized image format handling

### Changed
- Refactored codebase to follow DRY and KISS principles
- Removed duplicated decimal formatting code across model files
- Standardized URL construction for all API endpoints
- Centralized enum fallback behavior to improve maintainability
- Moved image format detection and conversion logic to dedicated service

## [1.4.3] - 2025-05-17

### Fixed
- Updated repository URL in Package.swift to match the correct GitHub repository

## [1.4.2] - 2025-05-17

### Improved
- Enhanced documentation with complete code examples and proper formatting
- Replaced placeholder code in README with actual implementation examples
- Updated Swift Package Manager integration example with realistic target names
- Improved SwiftUI example with comprehensive UI implementation
- Fixed all URLs and references in documentation

## [1.4.1] - 2025-05-17

### Added
- VS Code configuration for Swift development
- Added launch.json, tasks.json, and settings.json for optimal IDE experience
- Integrated debugging and testing support for VS Code

## [1.4.0] - 2025-05-17

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
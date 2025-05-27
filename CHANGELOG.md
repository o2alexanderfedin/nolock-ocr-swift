# Changelog

All notable changes to the NolockOCR Swift package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.17.0] - 2025-05-27

### Added
- Mock image data generation system for SmokeTests to eliminate external file dependencies
- Self-contained test infrastructure with JPEG-like mock data generation

### Fixed
- **CI/CD Pipeline**: Resolved all SwiftLint violations blocking pipeline execution
  - Fixed line length violations by extracting variables in test files
  - Replaced `count > 0` with `!isEmpty` for better Swift style
  - Replaced `try!` with proper `guard`/`fatalError` patterns
- **Test Dependencies**: Eliminated file dependency issues in SmokeTests
  - Replaced file-based image loading with in-memory mock data generation
  - Removed dependency on external `test_image.jpg` files
- **String Interpolation**: Fixed optional value handling in test logging

### Performance
- Reduced SmokeTests retry count from 20 to 3 attempts for faster CI/CD execution
- Decreased retry delay from 1.0 to 0.5 seconds between attempts
- Significantly improved CI/CD pipeline execution time (from 20+ minutes to ~5-10 minutes)

### Technical Improvements
- Enhanced code quality with systematic SwiftLint compliance
- Improved test reliability with self-contained mock data
- Better error handling patterns throughout test suite

## [1.15.1] - 2025-05-23

### Added
- Added BasicOCRProcessingTests class with modern Swift async/await patterns
- Implemented comprehensive test coverage for OCRProcessingService core functionality:
  - Service initialization and configuration
  - Empty queue behavior handling
  - Cancellation and status tracking
  - Work notification workflows
- Added mock image data generation system to avoid file path dependencies
- Improved test reliability with proper URLSession mocking for different endpoints
- Enhanced test documentation and code organization

### Fixed
- Resolved test image loading issues by implementing mock data generation
- Fixed JSON response structure mismatch between receipt and check endpoints
- Improved test stability by removing dependency on absolute file paths

## [1.15.0] - 2025-05-28

### Added
- Expanded OCRProcessingService test coverage with comprehensive test scenarios:
  - Added tests for large batch processing with performance metrics
  - Improved test stability with more robust mock implementations
  - Added tests for mixed document type batches
  - Added detailed assertions for all test cases

### Fixed
- Resolved CI/CD integration issues:
  - Added compatibility with GitHub Actions workflow
  - Fixed SwiftLint configuration for better test compatibility
  - Improved mock generation strategy for CI environments
  - Enhanced Mockingbird integration with fallback mechanisms

## [1.14.0] - 2025-05-27

### Added
- Enhanced test coverage for OCRProcessingService with new scenarios:
  - Added test for handling malformed JSON responses
  - Added test for concurrent batch processing with multiple notifications
  - Added test for cancellation during startup phase
  - Improved test documentation and assertions
- Replaced Mockingbird with manual mocks for better CI/CD compatibility:
  - Added MockURLSession for network testing
  - Added MockProcessingIO for processing service testing
  - Added comprehensive documentation for test mocks
  - Improved CI/CD workflow with fallback mechanisms
- Added integration guide for Mockingbird testing framework

## [1.13.0] - 2025-05-25

### Added
- Added GitHub Actions CI/CD workflow for automated build, test, and release
- Added SwiftLint configuration for code quality checks
- Added SwiftDoc configuration for API documentation generation
- Updated CONTRIBUTING.md with CI/CD information and improved guidelines

## [1.12.0] - 2025-05-25

### Added
- Integrated Mockingbird framework for improved test mocking
- Added example test implementations using Mockingbird
- Added mock generation script and configuration
- Added comprehensive OCRProcessingService documentation and examples
- Added BatchProcessingExample.swift showing complete implementation
- Added batch-processing-guide.md with detailed usage instructions

## [1.11.0] - 2025-05-24

### Added
- Improved test coverage for OCRProcessingService
- Added helper methods to OCRClient for test session injection
- Added tests for document-type specific processing paths
- Added tests for notifyWorkAvailable functionality
- Added tests for pendingWorkCounter behavior
- Added tests for network error handling (timeouts, server errors)
- Added tests for multiple notifyWorkAvailable calls
- Added tests for race condition handling
- Added tests for processing errors
- Added tests for mixed document types batch
- Added performance test for large batches
- Improved testability of OCRProcessingService by supporting test session injection

## [1.10.0] - 2025-05-22

### Added
- Enhanced test resource handling to show full file paths in error messages
- Added proper test resource failure handling with XCTFail instead of fatalError
- Added XCTExpectFailure tests to verify path inclusion in error messages
- Improved debugging experience when test resources are missing

## [1.9.0] - 2025-05-21

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
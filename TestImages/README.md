# Test Images for NolockOCR Swift Package

This directory is for test images used by the NolockOCR Swift package test suite. These images are used to test the package's ability to process various documents with the OCR API.

## Required Test Images

To run the tests, you need to place the following test images in this directory:

- `rental-bill.jpg` - Standard JPEG test image of a rental bill
- `pge-bill.HEIC` - HEIC format test image of a utility bill
- `fredmeyer-receipt.jpg` - JPEG receipt image 
- `fredmeyer-receipt-2.jpg` - Alternative JPEG receipt image
- `promo-check.HEIC` - HEIC format test image of a promotional check

## Obtaining Test Images

You can obtain these test images from one of the following sources:

1. From the main repository at: `/tests/fixtures/images/`
2. By downloading them from the project's shared resources
3. By creating your own test images with similar content

## Usage

These images are automatically used by the test suite when running tests. The test files are configured to look for these images in this directory first before searching in other locations.

## Adding New Test Images

When adding new test images, make sure to update the test files accordingly and document the new images in this README.

## Note on Image Formats

The tests require both JPEG and HEIC format images to properly test the file format conversion functionality. If you're creating your own test images, make sure to provide both formats.
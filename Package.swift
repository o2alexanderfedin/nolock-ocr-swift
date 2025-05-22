// swift-tools-version:5.9
//
// NolockOCR Swift Package
// https://github.com/o2alexanderfedin/nolock-ocr-swift
//
// Copyright (c) 2025 Nolock.social
// Licensed under MIT License
//

import PackageDescription

let package = Package(
    name: "NolockOCR",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "NolockOCR",
            targets: ["NolockOCR"]),
        .executable(
            name: "OCRExamples",
            targets: ["OCRExamples"])
    ],
    dependencies: [
        .package(url: "https://github.com/birdrides/mockingbird.git", from: "0.20.0"),
    ],
    targets: [
        .target(
            name: "NolockOCR",
            dependencies: [],
            path: "Sources"),
        .executableTarget(
            name: "OCRExamples",
            dependencies: ["NolockOCR"],
            path: "Examples",
            exclude: [
                "AsyncCheckProcessingExample.swift",
                "CheckProcessingExample.swift"
            ],
            sources: ["Main.swift"]),
        .testTarget(
            name: "NolockOCRTests",
            dependencies: [
                "NolockOCR",
                .product(name: "Mockingbird", package: "mockingbird")
            ],
            path: "Tests",
            exclude: ["README.md"],
            resources: [
                .process("Resources")
            ]),
    ],
    swiftLanguageVersions: [.v5]
)
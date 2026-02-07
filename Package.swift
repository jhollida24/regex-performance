// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RegexPerformance",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "RegexPerformance",
            targets: ["RegexPerformance"]),
    ],
    targets: [
        .target(
            name: "RegexPerformance",
            path: "RegexPerformance"),
        .testTarget(
            name: "RegexPerformanceTests",
            dependencies: ["RegexPerformance"],
            path: "RegexPerformanceTests"),
    ]
)

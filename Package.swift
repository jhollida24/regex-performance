// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RegexPerformance",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "RegexPerformanceApp",
            targets: ["App"]),
        .library(
            name: "RegexPerformance",
            targets: ["RegexPerformance"]),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: ["RegexPerformance"]),
        .target(
            name: "RegexPerformance",
            dependencies: []),
        .testTarget(
            name: "RegexPerformanceTests",
            dependencies: ["RegexPerformance"]),
    ]
)

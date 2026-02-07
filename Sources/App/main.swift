import Foundation
import RegexPerformance

print("=== Regex Performance Demo ===")
print("This demo simulates the performance issues that will be optimized.")
print()

let parser = RouteParser()
let presenter = FeaturePresenter(parser: parser)

// Create some test features
let features = [
    FeaturePresenter.Feature(id: "1", name: "Feature 1", url: "/feature/123"),
    FeaturePresenter.Feature(id: "2", name: "Feature 2", url: "/feature/456"),
    FeaturePresenter.Feature(id: "3", name: "Feature 3", url: "/feature/789"),
    FeaturePresenter.Feature(id: "4", name: "Feature 4", url: "/profile"),
    FeaturePresenter.Feature(id: "5", name: "Feature 5", url: "/settings"),
]

print("Processing \(features.count) features...")
print("Each feature will parse its route 3 times (update, log, check permissions)")
print()

let totalStart = Date()

for (index, feature) in features.enumerated() {
    print("Feature \(index + 1): \(feature.name)")
    
    // This will parse the route multiple times - demonstrating the performance issue
    let parseStart = Date()
    presenter.update(feature: feature)
    presenter.logTap()
    presenter.checkPermissions()
    let parseEnd = Date()
    
    let elapsed = parseEnd.timeIntervalSince(parseStart) * 1000
    print("  Time: \(String(format: "%.2f", elapsed))ms")
}

let totalEnd = Date()
let totalElapsed = totalEnd.timeIntervalSince(totalStart) * 1000

print()
print("Total time: \(String(format: "%.2f", totalElapsed))ms")
print("Average per feature: \(String(format: "%.2f", totalElapsed / Double(features.count)))ms")
print()
print("PERFORMANCE ISSUES:")
print("1. Each feature parses its route 3 times (update, log, permissions)")
print("2. Each parse compiles 5+ regex patterns from scratch")
print("3. URLRedactor would parse URLs twice (capability check + redaction)")
print()
print("See LESSON.md for how to optimize these issues!")

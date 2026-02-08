# Regex Performance Demo

This project demonstrates common regex compilation performance issues and how to fix them using systematic profiling and optimization.

## Overview

The app simulates a feature navigation system that parses routes using regular expressions. The initial implementation contains three performance anti-patterns:

1. **Redundant parsing** - Same route parsed multiple times
2. **Repeated regex compilation** - Patterns compiled on every use
3. **Duplicate work** - URL parsed twice in sequence

## Building and Running

### Requirements

- Xcode 15.0 or later
- iOS 17.0+ Simulator or device
- macOS 14.0+ (for Swift Package Manager)

### Build with Xcode

1. Open `RegexPerformance.xcodeproj` in Xcode
2. Select the `RegexPerformance` scheme
3. Choose iOS Simulator (iPhone 15 or later)
4. Press Cmd+R to build and run

### Build with Swift Package Manager

```bash
swift build
swift test
```

### Build from Command Line

```bash
xcodebuild -project RegexPerformance.xcodeproj \
  -scheme RegexPerformance \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build
```

## Profiling with Instruments

### Time Profiler

1. In Xcode, select Product → Profile (Cmd+I)
2. Choose "Time Profiler" template
3. Click Record
4. In the app:
   - Tap "Feature Detail" button
   - Tap "Simulate Updates" button
   - Wait for completion
5. Stop recording
6. Save the trace file for comparison
7. Examine the call tree:
   - Use "Top-Down" view to see call hierarchy
   - Use "Bottom-Up" view to find repeated work
   - Look for `NSRegularExpression.init` calls

### Allocations Instrument

1. Profile with "Allocations" template
2. Run the same test scenario
3. Look for memory churn in the Statistics view
4. Filter by "NSRegularExpression" to see compilation overhead

## Test Scenario

To reproduce the performance issues:

1. Launch the app
2. Tap "Feature Detail" button (navigates to detail view)
3. Tap "Simulate Updates" button (triggers 5 feature updates)
4. Observe in Instruments:
   - Multiple route parsing operations
   - Repeated regex compilations
   - Memory allocations

Each "Simulate Updates" tap causes:
- 5 feature updates
- 15 route parses (3 per update)
- 150 regex compilations (10 per parse × 15 parses)

## Project Structure

```
RegexPerformance/
├── RegexPerformanceApp/          # iOS app
│   ├── RegexPerformanceApp.swift # App entry point
│   ├── ContentView.swift         # Main screen
│   └── FeatureDetailView.swift   # Detail screen
├── Sources/RegexPerformance/     # Library code
│   ├── Routing/                  # Route parsing
│   │   ├── Route.swift
│   │   ├── RouteMatcher.swift    # ⚠️ Compiles regex on every call
│   │   └── RouteParser.swift
│   ├── Presentation/
│   │   └── FeaturePresenter.swift # ⚠️ Parses route 3 times
│   └── Redaction/
│       ├── URLRedactor.swift      # ⚠️ Parses URL twice
│       └── AggregateRedactor.swift
└── Tests/RegexPerformanceTests/
    └── URLRedactorTests.swift
```

## Performance Issues

### Issue 1: Redundant Parsing in FeaturePresenter

**Location**: `Sources/RegexPerformance/Presentation/FeaturePresenter.swift`

The presenter parses the same route three times:
- Line ~25: In `update()` method
- Line ~42: In `logTap()` method  
- Line ~58: In `checkPermissions()` method

### Issue 2: Repeated Regex Compilation in RouteMatcher

**Location**: `Sources/RegexPerformance/Routing/RouteMatcher.swift`

The matcher compiles NSRegularExpression on every call:
- Line ~18: In `matches()` method
- Line ~30: In `extract()` method

With 5 route matchers, each parse operation compiles 10 regex patterns.

### Issue 3: Duplicate Parsing in URLRedactor

**Location**: `Sources/RegexPerformance/Redaction/URLRedactor.swift`

The redactor parses URLs twice in sequence:
- Line ~12: `isCapableOfRedacting()` parses to check capability
- Line ~20: `redact()` parses the same URL again

## Next Steps

See `LESSON.md` for a complete tutorial on:
- Profiling with Instruments
- Analyzing performance bottlenecks
- Implementing optimizations with LLM assistance
- Measuring improvements

## License

This is a teaching example. Use freely for learning purposes.

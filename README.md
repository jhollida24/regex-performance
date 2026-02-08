# Regex Performance Demo

This project demonstrates three common regex compilation performance issues and how to fix them systematically using profiling and LLM-assisted refactoring.

## Overview

This is a simplified iOS app that recreates performance problems found in production codebases. The app demonstrates:

1. **Redundant parsing**: Same route parsed multiple times for one user interaction
2. **Repeated regex compilation**: Patterns compiled on every parse instead of once at initialization
3. **Duplicate parsing**: Same URL parsed twice in immediate succession

The repository includes the initial state with performance issues and three optimization commits that fix them step-by-step.

## Build and Run

### Requirements

- Xcode 15.0 or later
- iOS 17.0 or later
- macOS for running iOS Simulator

### Build with Xcode

```bash
xcodebuild -project RegexPerformance.xcodeproj \
  -scheme RegexPerformance \
  -sdk iphonesimulator \
  build
```

### Build with Swift Package Manager

```bash
swift build
```

### Run Tests

```bash
swift test
```

### Run on Simulator

1. Open `RegexPerformance.xcodeproj` in Xcode
2. Select a simulator (iPhone 15 recommended)
3. Press Cmd+R to build and run

## Profiling with Instruments

### Time Profiler

1. In Xcode: Product → Profile (Cmd+I)
2. Choose "Time Profiler"
3. Click Record
4. In the app:
   - Tap "Feature Detail" button
   - Tap "Simulate Updates" button
   - Wait for updates to complete
5. Stop recording
6. Save the trace file for comparison

### Key Views in Instruments

**Top-Down View**:
- Shows call hierarchy
- Use to understand what calls what
- Look for high "self time" to find actual expensive work

**Bottom-Up View**:
- Shows expensive operations and where they're called from
- Use to find repeated work
- Expand NSRegularExpression.init to see all call sites

### Allocations Instrument

1. In Xcode: Product → Profile (Cmd+I)
2. Choose "Allocations"
3. Run the same test scenario
4. Look for:
   - Total memory allocated
   - Persistent memory growth
   - Allocation churn (allocate/deallocate cycles)

## Test Scenario

To reproduce the performance issues:

1. Launch the app
2. Tap "Feature Detail" button (navigates to detail view)
3. Tap "Simulate Updates" button
4. Observe the updates happening (5 updates)

This triggers:
- 15 route parses (3 per update: update, log, permissions)
- Multiple regex compilations per parse
- Duplicate URL parsing in redaction

## Project Structure

```
RegexPerformance/
├── RegexPerformanceApp/           # iOS app
│   ├── RegexPerformanceApp.swift  # App entry point
│   ├── ContentView.swift          # Main screen with route buttons
│   ├── FeatureDetailView.swift    # Detail screen with update simulation
│   └── Assets.xcassets/           # App assets
├── Sources/RegexPerformance/      # Library code
│   ├── Routing/
│   │   ├── Route.swift            # Route model (path + parameters)
│   │   ├── RouteMatcher.swift     # Pattern matching (ISSUE: compiles regex on every call)
│   │   └── RouteParser.swift      # Route parser using matchers
│   ├── Presentation/
│   │   └── FeaturePresenter.swift # Presenter (ISSUE: parses same route multiple times)
│   └── Redaction/
│       ├── URLRedactor.swift      # URL redaction (ISSUE: parses URL twice)
│       └── AggregateRedactor.swift
└── Tests/RegexPerformanceTests/
    └── URLRedactorTests.swift     # Redaction tests
```

## Performance Issues

### Issue 1: Redundant Parsing in FeaturePresenter

**Location**: `Sources/RegexPerformance/Presentation/FeaturePresenter.swift`

**Problem**: Parses the same route three times:
- Line ~25: In `update()` when feature changes
- Line ~42: In `logTap()` for analytics
- Line ~58: In `checkPermissions()` for access control

**Impact**: 3x unnecessary parsing for one user interaction

**Fix**: [Commit b9e44e7](../../commit/b9e44e7) - Cache parsed route in Action struct

### Issue 2: Repeated Regex Compilation in RouteMatcher

**Location**: `Sources/RegexPerformance/Routing/RouteMatcher.swift`

**Problem**: Compiles NSRegularExpression on every call:
- Line ~18: In `matches()` method
- Line ~30: In `extract()` method
- 5 routes × 2 methods = 10 compilations per parse

**Impact**: Accounts for about half of total parse time

**Fix**: [Commit bf4dee2](../../commit/bf4dee2) - Pre-compile patterns at initialization

### Issue 3: Duplicate Parsing in URLRedactor

**Location**: `Sources/RegexPerformance/Redaction/URLRedactor.swift`

**Problem**: Two methods that both parse:
- Line ~12: `isCapableOfRedacting()` parses URL
- Line ~20: `redact()` parses the same URL again
- Called sequentially on the same URL

**Impact**: 2x parsing in immediate succession

**Fix**: [Commit e88e5dc](../../commit/e88e5dc) - Return Result enum, collapse into one method

## Optimization Commits

The repository includes these commits in order:

1. **[95d42e8](../../commit/95d42e8)** - Initial project with performance issues
2. **[b9e44e7](../../commit/b9e44e7)** - Reuse parsed routes in FeaturePresenter
3. **[bf4dee2](../../commit/bf4dee2)** - Pre-compile regex patterns in RouteMatcher
4. **[e88e5dc](../../commit/e88e5dc)** - Eliminate duplicate parsing in URLRedactor

Check out each commit to see the state before and after each optimization.

## Walking Through the Optimizations

### Start with Initial State

```bash
git checkout 95d42e8
```

Profile this state to establish your baseline.

### Apply Optimization 1

```bash
git checkout b9e44e7
```

Profile again and compare to baseline.

### Apply Optimization 2

```bash
git checkout bf4dee2
```

Profile again and measure the improvement.

### Apply Optimization 3

```bash
git checkout e88e5dc
```

Final profiling to see the cumulative effect.

## Expected Results

Results will vary based on your hardware and iOS version, but you should see:

- **Parse time**: 80-90% reduction
- **Regex initialization time**: Near 100% reduction (moved to startup)
- **Memory churn**: 80-90% reduction
- **Persistent memory**: Small increase (~1MB) for compiled patterns

## Complete Tutorial

See [LESSON.md](LESSON.md) for the complete tutorial including:
- How to read performance profiles
- How to form optimization theories
- How to work with LLMs for implementation
- Detailed explanations of each optimization
- Prompting examples and techniques

## License

This project is for educational purposes.

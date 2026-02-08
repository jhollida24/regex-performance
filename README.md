# Regex Performance Optimization Demo

This repository demonstrates a systematic approach to identifying and fixing regex compilation performance issues in an iOS app.

## Building

You can build this project using either Xcode or the command line:

### Using Xcode

```bash
open RegexPerformance.xcodeproj
```

Then press Cmd+R to build and run on a simulator.

### Using Command Line

Build for iOS Simulator:

```bash
xcodebuild -project RegexPerformance.xcodeproj \
  -scheme RegexPerformance \
  -sdk iphonesimulator \
  -configuration Release \
  build
```

## Running

### From Xcode

1. Open `RegexPerformance.xcodeproj`
2. Select a simulator (e.g., iPhone 15)
3. Press Cmd+R to run
4. Tap "Feature Detail" button to trigger the performance issue

### From Command Line

First, find an available simulator:

```bash
xcrun simctl list devices available | grep iPhone
```

Then boot it (replace with your simulator name):

```bash
xcrun simctl boot "iPhone 15" || true
```

Build and install:

```bash
# Build the app
xcodebuild -project RegexPerformance.xcodeproj \
  -scheme RegexPerformance \
  -sdk iphonesimulator \
  -configuration Release \
  -derivedDataPath ./build

# Install to booted simulator
xcrun simctl install booted ./build/Build/Products/Release-iphonesimulator/RegexPerformance.app

# Launch the app
xcrun simctl launch booted com.example.RegexPerformance
```

## Profiling with Instruments

### From Xcode

1. Open the project in Xcode
2. Product → Profile (Cmd+I)
3. Select "Time Profiler"
4. Click Record
5. Tap "Feature Detail" button 5-10 times
6. Stop recording
7. Analyze the results

### From Command Line

```bash
# Build in release mode
xcodebuild -project RegexPerformance.xcodeproj \
  -scheme RegexPerformance \
  -sdk iphonesimulator \
  -configuration Release \
  build

# Get the app bundle path
APP_PATH=$(find ./build -name "RegexPerformance.app" | head -1)

# Boot a simulator if needed
xcrun simctl boot "iPhone 15" || true

# Install the app
xcrun simctl install booted "$APP_PATH"

# Profile with Instruments
instruments -t "Time Profiler" \
  -w "iPhone 15" \
  com.example.RegexPerformance
```

**Note:** You'll need to manually interact with the app (tap "Feature Detail" button) while Instruments is recording.

## Test Scenario

To reproduce the performance issue:

1. Launch the app
2. Tap "Feature Detail" button
3. Tap "Simulate Updates" button
4. Observe the console output showing repeated parsing

This demonstrates the performance issues that will be optimized.

## Following the Lesson

See [LESSON.md](LESSON.md) for the complete guide.

Each commit demonstrates a specific optimization:
- [Commit 7bfae2b](https://github.com/jhollida24/regex-performance/tree/spm-version/commit/7bfae2b): Initial state with performance issues
- [Commit 7223b8f](https://github.com/jhollida24/regex-performance/tree/spm-version/commit/7223b8f): Reuse parsed routes
- [Commit 9e49443](https://github.com/jhollida24/regex-performance/tree/spm-version/commit/9e49443): Pre-compile regex patterns
- [Commit 2df2626](https://github.com/jhollida24/regex-performance/tree/spm-version/commit/2df2626): Eliminate duplicate parsing
- [Commit fcd2250](https://github.com/jhollida24/regex-performance/tree/spm-version/commit/fcd2250): Complete lesson

## Your Results

Profile the app and record your results:

**Before optimizations:**
- Parse time: ___ ms
- Time in regex initialization: ___ ms
- Main thread blocked: ___ ms

**After optimizations:**
- Parse time: ___ ms (___% reduction)
- Time in regex initialization: ___ ms (___% reduction)
- Main thread blocked: ___ ms (___% reduction)
- Memory cost: +___ MB persistent

## Performance Issues Demonstrated

1. **Redundant Parsing**: FeaturePresenter parses the same route 3 times
2. **Repeated Regex Compilation**: RouteMatcher compiles regex on every call
3. **Duplicate Parsing**: URLRedactor parses URLs twice (capability check + redaction)

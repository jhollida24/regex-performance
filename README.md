# Regex Performance Optimization Demo

This repository demonstrates a systematic approach to identifying and fixing regex compilation performance issues.

## Building and Running

This is a Swift Package Manager (SPM) project. You can build and run it from the command line:

```bash
# Build the project
swift build

# Run the demo app
swift run RegexPerformanceApp

# Run tests
swift test
```

## Profiling

To profile the performance issues, you can use Instruments:

```bash
# Build in release mode
swift build -c release

# The executable will be in .build/release/RegexPerformanceApp
# You can profile it with Instruments Time Profiler

# Or run it with the time command to see basic timing
time .build/release/RegexPerformanceApp
```

For iOS profiling, you would typically:
1. Build the app for iOS
2. Deploy to simulator or device
3. Attach Instruments Time Profiler
4. Execute the test scenario
5. Analyze the results

## Test Scenario

The demo simulates:
1. Creating 10 features
2. For each feature:
   - Update the presenter (parses route)
   - Log a tap event (parses route again)
   - Check permissions (parses route again)

This demonstrates the performance issues that will be optimized.

## Following the Lesson

See [LESSON.md](LESSON.md) for the complete guide.

Each commit demonstrates a specific optimization:
- [Commit 1](https://github.com/jhollida24/regex-performance/commit/HASH1): Initial state with performance issues
- [Commit 2](https://github.com/jhollida24/regex-performance/commit/HASH2): Reuse parsed routes
- [Commit 3](https://github.com/jhollida24/regex-performance/commit/HASH3): Pre-compile regex patterns
- [Commit 4](https://github.com/jhollida24/regex-performance/commit/HASH4): Eliminate duplicate parsing
- [Commit 5](https://github.com/jhollida24/regex-performance/commit/HASH5): Complete lesson

## Your Results

Profile the app and record your results:

**Before optimizations:**
- Total time: ___ ms
- Average per feature: ___ ms

**After optimizations:**
- Total time: ___ ms (___% reduction)
- Average per feature: ___ ms (___% reduction)

## Performance Issues Demonstrated

1. **Redundant Parsing**: FeaturePresenter parses the same route 3 times
2. **Repeated Regex Compilation**: RouteMatcher compiles regex on every call
3. **Duplicate Parsing**: URLRedactor parses URLs twice (capability check + redaction)

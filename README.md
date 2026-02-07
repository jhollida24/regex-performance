# Regex Performance Optimization Demo

This repository demonstrates a systematic approach to identifying and fixing regex compilation performance issues.

## Building

This is a Swift package that can be built and tested:

```bash
swift build
swift test
```

## Profiling

To profile the code:

1. Open the package in Xcode: `open Package.swift`
2. Create a new iOS app target that uses this package
3. Run with Instruments Time Profiler
4. Execute the test scenario: tap "Feature Detail" button multiple times

Test scenario:
1. Launch the app
2. Tap "Feature Detail" button 5-10 times
3. Stop recording and analyze

## Following the Lesson

See [LESSON.md](LESSON.md) for the complete guide (will be added in final commit).

Each commit demonstrates a specific optimization:
- [Commit 1d5e047](../../commit/1d5e047): Initial state with performance issues
- [Commit 33e4c08](../../commit/33e4c08): Reuse parsed routes in FeaturePresenter
- [Commit 1b3ece8](../../commit/1b3ece8): Pre-compile regex patterns in RouteMatcher
- [Commit 8011af7](../../commit/8011af7): Eliminate duplicate parsing in URLRedactor
- [Commit 7ea0365](../../commit/7ea0365): Complete lesson

## Your Results

Profile the app and record your results:

**Before optimizations:**
- Parse time: ___ ms
- Memory churn: ___ MB

**After optimizations:**
- Parse time: ___ ms (___% reduction)
- Memory churn: ___ MB (___% reduction)
- Memory cost: +___ MB persistent

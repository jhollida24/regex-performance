# Debugging Performance with LLMs: A Systematic Approach

**Subtitle:** Fixing a sluggish UI interaction through measurement, analysis, and targeted optimization

---

## Introduction: The Bug Report

Bug ticket filed: "Tapping the Feature Detail button is slow"

Not a crash, not obviously broken—just sluggish. The kind of issue that's easy to deprioritize but affects every user.

**Why This Matters:**
- Performance issues are often vague and hard to reproduce
- Users rarely report "slow" until it's *really* slow
- Small delays compound across millions of users

**The Approach:**

This post demonstrates a systematic approach to:
1. **Measure** the problem
2. **Analyze** what's causing it
3. **Theorize** solutions
4. **Implement** fixes with LLM assistance
5. **Verify** the improvements

You can follow along by cloning this repository and profiling the app yourself.

---

## Phase 1: Measure the Problem

### Setting Up the Measurement

**The First Rule: Establish a Baseline**

Before changing anything, I needed reproducible measurements.

**Creating a Test Scenario:**

```
1. Launch the app
2. Tap "Feature Detail" button
3. Tap "Simulate Updates" button (simulates 5 feature updates)
4. Observe the repeated parsing in the console
```

**Using Instruments Time Profiler:**

From Xcode:
1. Open `RegexPerformance.xcodeproj`
2. Product → Profile (Cmd+I)
3. Select "Time Profiler"
4. Click Record
5. Perform the test scenario
6. Stop recording

Or from command line:
```bash
# Build the app
xcodebuild -project RegexPerformance.xcodeproj \
  -scheme RegexPerformance \
  -sdk iphonesimulator \
  -configuration Release \
  build

# Boot a simulator
xcrun simctl boot "iPhone 15" || true

# Install the app
xcrun simctl install booted \
  ./build/Build/Products/Release-iphonesimulator/RegexPerformance.app

# Profile with Instruments (you'll need to interact with the app manually)
instruments -t "Time Profiler" -w "iPhone 15" com.example.RegexPerformance
```

**Placeholder for profiling data:**
> **[Profile the app and record your baseline numbers here]**
> - Total time: ___ ms
> - Time in regex initialization: ___ ms
> - Time in route parsing: ___ ms

Reference: See the initial state in [commit 7bfae2b](https://github.com/jhollida24/regex-performance/tree/spm-version/commit/7bfae2b)

**Also Capture Memory Data:**

From Xcode:
1. Product → Profile (Cmd+I)
2. Select "Allocations"
3. Click Record
4. Perform the test scenario
5. Stop recording

Or from command line:
```bash
instruments -t "Allocations" -w "iPhone 15" com.example.RegexPerformance
```

---

## Phase 2: Analyze the Profile

### Reading the Time Profile (Top-Down View)

**Looking at the Call Tree:**

When analyzing a Time Profiler trace, I start with the top-down view to understand the call hierarchy.

**What I Found:**

The profile revealed:
- Significant time in high-level UI update code
- Drilling down: time in route parsing logic
- Further down: heavy time in regular expression initialization
- All on the main thread (UI-blocking)

**The Call Pattern:**
```
Screen update logic (total time)
  → Route parsing (total time)
    → Pattern matching (total time)
      → Regex compilation (self time) ← Heavy work here
```

**Key Observation:**

The "total" time is high at each level, but the "self" time is concentrated in regex compilation. This suggests the expensive operation is the leaf work, not the coordination.

### Switching to Bottom-Up View

**Why Bottom-Up Matters:**

The top-down view shows *where* time is spent in the call hierarchy. The bottom-up view shows *how often* expensive operations are called and *from where*.

**In Instruments:**
- Switch from "Call Tree" to "Bottom Up"
- Focus on the expensive function (regex compilation)
- Expand to see all the call sites

**What Bottom-Up Revealed:**

Looking at regex compilation from the bottom up:
```
NSRegularExpression.init (total time)
  ← Called from Matcher.matches (multiple times)
    ← Called from RouteParser.parse
      ← Called from FeaturePresenter.update
      ← Called from FeaturePresenter.logTap
      ← Called from FeaturePresenter.checkPermissions
      ← Called from URLRedactor.isCapableOfRedacting
      ← Called from URLRedactor.redact
      ← [other call sites...]
```

**The Key Insights:**

The same expensive operation (regex compilation) is being called from:
1. **Multiple different places** - Different features/components are all parsing routes
2. **Multiple times from the same place** - FeaturePresenter shows up repeatedly
3. **Sequentially for the same input** - Redaction check followed immediately by redaction

### Analyzing Memory Allocations

**Looking at the Allocations Instrument:**

Switching to the Allocations trace:
- Filter to URL/routing-related types
- Look at allocation patterns
- Check for high churn (allocate + immediate free)

**What I Found:**
- Large amount of memory allocated in URL handling during the test
- Most immediately deallocated (high churn)
- Pattern: same types allocated repeatedly

**The Pattern:**

High memory churn + expensive initialization = repeated creation of the same expensive objects.

### Forming Theories

Based on the profile analysis, I formed three theories about optimization opportunities:

**Theory 1: FeaturePresenter (`Sources/RegexPerformance/Presentation/FeaturePresenter.swift`) is parsing the same route multiple times**

Evidence:
- Bottom-up view shows multiple calls from this component
- Parsing on updates, logging, and permissions checks
- Could reuse the parsed result

**Theory 2: RouteMatcher (`Sources/RegexPerformance/Routing/RouteMatcher.swift`) is compiling regex on every parse**

Evidence:
- Every parse creates fresh NSRegularExpression instances
- About half the time spent in initialization
- These could be created once and reused
- Trade-off: persistent memory for speed

**Theory 3: URL redaction is parsing each URL twice**

Evidence:
- Bottom-up shows sequential calls: capability check, then redact
- Both operations parse the same URL
- Could collapse into single operation

---

## Lesson 1: Reading Performance Profiles

**Two Views, Two Purposes**

**Top-Down View: Understanding Call Hierarchy**
- Shows the path from high-level operations to low-level work
- Helps you understand *why* expensive operations are happening
- Use "total time" to follow the expensive path
- Use "self time" to find where actual work occurs

**Bottom-Up View: Finding Repeated Work**
- Shows all the places that call expensive operations
- Helps you identify redundant or unnecessary calls
- Essential for finding optimization opportunities
- Look for:
  - Multiple call sites for the same expensive operation
  - Repeated calls from the same location
  - Sequential calls that could be combined

**The Process:**
1. Start with top-down to understand the problem
2. Switch to bottom-up to identify optimization opportunities
3. Form theories based on what you see
4. Use those theories to guide your fixes

---

## Phase 3: Optimization #1 - Reuse Parsed Routes

### The Theory

FeaturePresenter is parsing the same route multiple times. Reuse the parsed route alongside the feature to avoid redundant parsing.

### Working with the LLM

**Prompt 1: Planning**

```
FeaturePresenter (`Sources/RegexPerformance/Presentation/FeaturePresenter.swift`) 
parses the same Route multiple times. Look at line 25—it parses when 
the feature updates. Then look at line 42—it parses again when logging. 
And line 58—parses again for permissions.

I want to reuse the parsed route alongside the feature. Create an 
Action type that contains both the analytics event and the parsed 
Route. Parse once when the feature changes, reuse for all operations.

Show me your plan for refactoring this.
```

**After LLM provides plan, human reviews it, then:**

```
Go ahead and execute the plan.
```

**After LLM provides code:**
- Human examines the diff
- Human verifies the changes
- If issues found, human provides feedback to LLM
- Human commits when satisfied

**The Changes:**

```diff
 class FeaturePresenter: ObservableObject {
     @Published var model: FeatureModel?
+    
+    struct Action {
+        let feature: Feature
+        let route: Route?
+    }
+    
+    private var currentAction: Action?
     
-    func update(feature: Feature) {
-        let route = parser.parse(feature.url)
-        model = FeatureModel(feature: feature, route: route)
+    func update(feature: Feature) {
+        let route = parser.parse(feature.url)
+        currentAction = Action(feature: feature, route: route)
+        model = FeatureModel(feature: feature, route: route)
     }
     
     func logTap() {
-        let route = parser.parse(currentFeature.url)
-        analytics.log(event: .tap, route: route)
+        guard let action = currentAction else { return }
+        analytics.log(event: .tap, route: action.route)
     }
     
     func checkPermissions() {
-        let route = parser.parse(currentFeature.url)
-        permissions.check(route: route)
+        guard let action = currentAction else { return }
+        permissions.check(route: action.route)
     }
 }
```

See the full changes in [commit 7223b8f](https://github.com/jhollida24/regex-performance/tree/spm-version/commit/7223b8f)

**Placeholder for profiling:**
> **[Profile again and record the improvement]**
> - Total parse time: ___ ms (was ___ ms)
> - Reduction: ___%

---

## Phase 4: Optimization #2 - Pre-compile Regex Patterns

### The Theory

RouteMatcher is compiling NSRegularExpression on every parse. About half the time is spent in regex compilation. Pre-compile the patterns once at initialization and store the NSRegularExpression instances.

### Working with the LLM

**Prompt 1: Planning**

```
RouteMatcher (`Sources/RegexPerformance/Routing/RouteMatcher.swift`) stores 
regex patterns as strings. Look at line 18—it compiles the regex on 
every call to matches(). Profiling shows this accounts for about half 
of the total parse time.

I want to pre-compile the patterns once at initialization. Store 
NSRegularExpression instances instead of strings.

Show me your plan for refactoring this.
```

**LLM plan would include:**
- Memory trade-off estimation
- Thread-safety validation
- Implementation approach

**Human reviews plan, then:**

```
Go ahead and execute the plan.
```

**Human reviews the generated code:**
- Examines the diff
- Verifies correctness
- Provides feedback if needed
- Commits when satisfied

**The Changes:**

```diff
 struct RouteMatcher {
-    let pattern: String
+    let regex: NSRegularExpression
     let template: String
     
-    init(pattern: String, template: String) {
-        self.pattern = pattern
+    init(regex: NSRegularExpression, template: String) {
+        self.regex = regex
         self.template = template
     }
     
     func matches(_ input: String) -> Bool {
-        guard let regex = try? NSRegularExpression(pattern: pattern) else {
-            return false
-        }
         let range = NSRange(input.startIndex..., in: input)
         return regex.firstMatch(in: input, range: range) != nil
     }
 }
```

And in RouteParser:

```diff
 init() {
-    homeRoute = RouteMatcher(pattern: "^/home$", template: "/home")
-    profileRoute = RouteMatcher(pattern: "^/profile$", template: "/profile")
+    let homeRegex = try! NSRegularExpression(pattern: "^/home$")
+    let profileRegex = try! NSRegularExpression(pattern: "^/profile$")
+    // ... etc
+    
+    homeRoute = RouteMatcher(regex: homeRegex, template: "/home")
+    profileRoute = RouteMatcher(regex: profileRegex, template: "/profile")
 }
```

See the full changes in [commit 9e49443](https://github.com/jhollida24/regex-performance/tree/spm-version/commit/9e49443)

**Placeholder for profiling:**
> **[Profile again and record the improvement]**
> - Total parse time: ___ ms (was ___ ms)
> - Time in regex initialization: ___ ms (was ___ ms)
> - Reduction: ___%
> - Memory cost: ___ MB persistent

---

## Phase 5: Optimization #3 - Eliminate Duplicate Parsing

### The Theory

URLRedactor (`Sources/RegexPerformance/Redaction/URLRedactor.swift`) parses each URL twice. Look at line 12—isCapableOfRedacting parses the URL. Then look at line 20—redact parses it again. Collapse the capability check into the redact method and return a result enum.

### Working with the LLM

**Prompt 1: Planning**

```
URLRedactor (`Sources/RegexPerformance/Redaction/URLRedactor.swift`) parses 
each URL twice. Look at line 12—isCapableOfRedacting parses the URL. 
Then look at line 20—redact parses it again.

I want to remove isCapableOfRedacting and have redact() return an 
enum indicating success, not-applicable, or error. AggregateRedactor 
would try each redactor until one succeeds.

Show me your plan for refactoring this.
```

**Human reviews plan, approves, reviews code, provides feedback or commits**

**The Changes:**

```diff
+enum RedactionResult {
+    case redacted(String)
+    case notApplicable
+}
+
 protocol URLRedactor {
-    func isCapableOfRedacting(urlString: String) -> Bool
-    func redact(urlString: String) -> String
+    func redact(urlString: String) -> RedactionResult
 }

 class ClientRouteURLRedactor: URLRedactor {
-    func isCapableOfRedacting(urlString: String) -> Bool {
-        return parser.parse(urlString) != nil
-    }
-    
-    func redact(urlString: String) -> String {
+    func redact(urlString: String) -> RedactionResult {
         guard let route = parser.parse(urlString) else {
-            return urlString
+            return .notApplicable
         }
         
         if urlString.hasPrefix("/feature/") {
-            return "/feature/:id"
+            return .redacted("/feature/:id")
         }
         
-        return urlString
+        return .redacted(urlString)
     }
 }
```

See the full changes in [commit 2df2626](https://github.com/jhollida24/regex-performance/tree/spm-version/commit/2df2626)

**Placeholder for profiling:**
> **[Profile again and record the final improvement]**
> - Total parse time: ___ ms (was ___ ms initially)
> - Total reduction: ___%
> - Memory churn: ___ MB (was ___ MB initially)
> - Reduction: ___%

---

## Lesson 2: Working Effectively with LLMs

**The Pattern:**

When working with an LLM on performance optimizations:

1. **State your theory with file paths**
   - Use monospace for paths: `Sources/RegexPerformance/Routing/RouteMatcher.swift`
   - Point to specific lines and explain why: "Look at line 18—it compiles the regex on every call"
   - Use relative measurements: "about half the time", "most of the allocations"

2. **Ask "Show me your plan"**
   - Let the LLM validate assumptions (thread-safety, memory cost)
   - Review the plan before implementation

3. **Say "Go ahead and execute the plan"**
   - Simple, direct approval

4. **Review the patch yourself**
   - Examine the diff
   - Verify correctness
   - Provide feedback if needed, or commit

5. **Commit with clear message**
   - Explain the optimization
   - Note the trade-offs

**Example flow:**
```
You: [Theory with file paths and line numbers] Show me your plan.
LLM: [Outlines approach, validates assumptions]
You: Go ahead and execute the plan.
LLM: [Provides implementation]
You: [Reviews diff, commits or provides feedback]
```

---

## Phase 6: Measuring the Results

**Running the Same Test:**

From Xcode:
1. Product → Profile (Cmd+I)
2. Select "Time Profiler"
3. Click Record
4. Tap "Feature Detail" → "Simulate Updates"
5. Stop recording
6. Compare with your baseline trace

Or from command line:
```bash
# Profile with Instruments (you'll need to interact with the app)
instruments -t "Time Profiler" -w "iPhone 15" com.example.RegexPerformance
```

Same test scenario: Tap "Feature Detail" → "Simulate Updates" (5 feature updates, each parsed 3 times).

**Summary of improvements:**
> **[Your profiling results]**
> - Total time: ___ ms → ___ ms (___% reduction)
> - Time in regex init: ___ ms → ___ ms (___% reduction)
> - Memory churn: ___ MB → ___ MB (___% reduction)
> - Memory cost: +___ MB persistent

Reference final state in [commit 2df2626](https://github.com/jhollida24/regex-performance/tree/spm-version/commit/2df2626)

---

## Conclusion: The Process

**What We Achieved:**

Three focused optimizations based on profile analysis:
1. Reused parsed routes in FeaturePresenter (eliminated redundant parsing)
2. Pre-compiled regex patterns in RouteMatcher (eliminated repeated compilation)
3. Removed duplicate parsing in URLRedactor (eliminated unnecessary work)

**The Process:**
1. **Measure** - Establish baseline with Instruments
2. **Analyze** - Use top-down and bottom-up views to understand the problem
3. **Theorize** - Form hypotheses about optimizations
4. **Implement** - Work with LLM: theory → plan → code → review
5. **Verify** - Measure with the same test scenario

**The Division of Labor:**

**You (the human):**
- Measure with Instruments
- Analyze profiles (top-down and bottom-up)
- Form theories about optimizations
- Reason through trade-offs
- Verify results

**The LLM:**
- Implement refactorings based on your theories
- Update tests to match API changes
- Review code for common issues
- Generate boilerplate

**Try It Yourself:**

```bash
git clone https://github.com/jhollida24/regex-performance
cd regex-performance
git checkout spm-version
open RegexPerformance.xcodeproj
```

Build and profile the app yourself (Cmd+I). Walk through each commit to see the optimizations.

Next time you get a performance bug:
1. Profile it with Instruments (save the trace!)
2. Analyze top-down and bottom-up views yourself
3. Form theories about the cause
4. Work with an LLM: state your theory, ask for a plan, then implementation
5. Measure your results

The LLM is a coding assistant, not a performance analyst. You do the thinking, it does the typing.

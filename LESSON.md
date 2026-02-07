# Debugging Performance with LLMs: A Systematic Approach

**Fixing a sluggish UI interaction through measurement, analysis, and targeted optimization**

---

## Introduction: The Bug Report

Bug ticket filed: "Tapping the Feature Detail button is slow to open"

Not a crash, not obviously broken—just sluggish. The kind of issue that's easy to deprioritize but affects every user every time they interact with that feature.

Performance issues are often vague and hard to reproduce. Users rarely report "slow" until it's *really* slow. But small delays compound across millions of users and hundreds of interactions per day.

This post demonstrates a systematic approach to fixing performance issues:
1. **Measure** the problem
2. **Analyze** what's causing it
3. **Theorize** solutions
4. **Implement** fixes with LLM assistance
5. **Verify** the improvements

You can follow along by cloning this repository and profiling the app yourself. Each commit demonstrates a specific optimization.

---

## Phase 1: Measure the Problem

### Setting Up the Measurement

**The First Rule: Establish a Baseline**

Before changing anything, I needed reproducible measurements.

**Creating a Test Scenario:**
```
1. Launch the app
2. Tap "Feature Detail" button 5 times
3. Return to home
```

Why this scenario?
- Represents real user behavior
- Repeatable
- Exercises the reported slow interaction

**Using Instruments Time Profiler:**

```bash
# From the repository root
instruments -t "Time Profiler" -D trace_before.trace \
  -w <device-id> com.example.RegexPerformance
```

**Using Instruments Allocations:**

```bash
instruments -t "Allocations" -D allocations_before.trace \
  -w <device-id> com.example.RegexPerformance
```

Same test scenario, different instrument.

> **[Profile the app and record your baseline numbers here]**
> - Total parse time: ___ ms
> - Time in regex initialization: ___ ms
> - Main thread blocked: ___ ms
> - Memory churned: ___ MB

**Reference:** See the initial state in [commit 1d5e047](https://github.com/jhollida24/regex-performance/commit/1d5e047213a2fb64da462367cd0aba5a3cc87055)

---

## Phase 2: Analyze the Profile

### Reading the Time Profile (Top-Down View)

When analyzing a Time Profiler trace, I start with the top-down view to understand the call hierarchy.

**What I Found:**

The profile revealed:
- Significant time in high-level UI update code
- Drilling down: time in route parsing logic
- Further down: heavy time in regular expression initialization
- All on the main thread (UI-blocking)

**The Call Pattern:**
```
Screen update logic (total time high)
  → Route parsing (total time high)
    → Pattern matching (total time high)
      → Regex compilation (self time high) ← Heavy work here
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
NSRegularExpression.init (heavy self time)
  ← Called from RouteMatcher.matches (multiple times)
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

**Theory 1: FeaturePresenter (`RegexPerformance/Presentation/FeaturePresenter.swift`) is parsing the same route multiple times**

Evidence:
- Bottom-up view shows multiple calls from this component
- Likely parsing on updates, logging, and permission checks
- Could reuse the parsed result

**Theory 2: RouteMatcher (`RegexPerformance/Routing/RouteMatcher.swift`) is compiling regex on every parse**

Evidence:
- Every parse creates fresh NSRegularExpression instances
- About half the time is spent in regex initialization
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

**Key Takeaway:** Don't just look at one view. Top-down tells you *what's slow*, bottom-up tells you *why it's being called so much*.

---

## Phase 3: Optimization #1 - Reuse Parsed Routes

### The Theory

FeaturePresenter is parsing the same Route multiple times. Reuse the parsed route to avoid redundant parsing.

### Working with the LLM

**Prompt 1: Planning**

```
FeaturePresenter (`RegexPerformance/Presentation/FeaturePresenter.swift`) 
parses the same Route multiple times. Look at line 36—it parses when 
the feature updates. Then look at line 42—it parses again when logging. 
And line 48—parses again for permissions.

I want to reuse the parsed route. Create an Action type that contains 
both the feature and the parsed Route. Parse once when the feature 
changes, reuse for all operations.

Show me your plan for refactoring this.
```

**LLM Response:**
[LLM outlines its approach: create Action struct, parse once in update method, store in currentAction, reuse in other methods]

**Prompt 2: Approval**

```
Go ahead and execute the plan.
```

**LLM Provides Implementation**

**Human Review:**
- Examine the diff
- Verify the changes
- If issues found, provide feedback to LLM
- Commit when satisfied

### The Changes

```diff
 class FeaturePresenter: ObservableObject {
     @Published var model: FeatureModel?
     
     private let parser = RouteParser()
     private var cancellables = Set<AnyCancellable>()
     
     struct Feature {
         let id: String
         let url: String
         let title: String
     }
     
+    struct Action {
+        let feature: Feature
+        let route: Route?
+        
+        var requiresPermissions: Bool {
+            route?.path.contains("feature") ?? false
+        }
+    }
+    
     struct FeatureModel {
         let feature: Feature
         let route: Route?
     }
     
+    private var currentAction: Action?
+    
     init() {
         // Simulate feature updates
     }
     
     func update(feature: Feature) {
-        let route = parser.parse(feature.url)
-        model = FeatureModel(feature: feature, route: route)
+        // Optimization: parse once and store in Action
+        let route = parser.parse(feature.url)
+        let action = Action(feature: feature, route: route)
+        currentAction = action
+        model = FeatureModel(feature: feature, route: route)
     }
     
-    func logTap(feature: Feature) {
-        let route = parser.parse(feature.url)
-        print("Analytics: Tapped feature with route \(route?.path ?? "unknown")")
+    func logTap() {
+        // Optimization: reuse the parsed route from currentAction
+        guard let action = currentAction else { return }
+        print("Analytics: Tapped feature with route \(action.route?.path ?? "unknown")")
     }
     
-    func checkPermissions(feature: Feature) -> Bool {
-        let route = parser.parse(feature.url)
-        return route?.path.contains("feature") ?? false
+    func checkPermissions() -> Bool {
+        // Optimization: reuse the parsed route from currentAction
+        guard let action = currentAction else { return }
+        return action.requiresPermissions
     }
 }
```

**Reference:** See the full changes in [commit 33e4c08](https://github.com/jhollida24/regex-performance/commit/33e4c08e3a9563f4884d165cf0369f8d7eb49291)

### Measuring the Improvement

> **[Profile again and record the improvement]**
> - Total parse time: ___ ms (was ___ ms)
> - Reduction: ___%

---

## Phase 4: Optimization #2 - Pre-compile Regex Patterns

### The Theory

RouteMatcher is compiling NSRegularExpression on every parse. About half the total parse time is spent in regex compilation. Pre-compile the patterns once at initialization and store the NSRegularExpression instances.

### Working with the LLM

**Prompt 1: Planning**

```
RouteMatcher (`RegexPerformance/Routing/RouteMatcher.swift`) stores 
regex patterns as strings. Look at line 18—it compiles the regex on 
every call to matches(). Profiling shows this accounts for about half 
of the total parse time.

I want to pre-compile the patterns once at initialization. Store 
NSRegularExpression instances instead of strings.

Show me your plan for refactoring this.
```

**LLM Response:**
[LLM outlines approach: change stored property type, update initializer, remove compilation from matching, validate thread-safety, estimate memory cost]

**Prompt 2: Approval**

```
Go ahead and execute the plan.
```

**LLM Provides Matcher Implementation**

**Prompt 3: Update Callers**

```
Now I need to update the code that creates RouteMatcher instances. 
Look at RouteParser (`RegexPerformance/Routing/RouteParser.swift`) 
line 15—it creates matchers with string patterns.

Show me your plan for updating this to compile the regex patterns 
and pass NSRegularExpression instances to RouteMatcher.
```

**LLM Response:**
[LLM outlines approach: compile patterns in init, handle errors, use compactMap]

**Prompt 4: Approval**

```
Go ahead and execute the plan.
```

**LLM Provides Updated Caller Code**

**Human Review and Commit**

### The Changes

**RouteMatcher.swift:**
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
-        // Performance issue: compiling regex on every call!
-        guard let regex = try? NSRegularExpression(pattern: pattern) else {
-            return false
-        }
+        // Optimization: reuse pre-compiled regex
         let range = NSRange(input.startIndex..., in: input)
         return regex.firstMatch(in: input, range: range) != nil
     }
     
     func extract(from input: String) -> [String: String]? {
-        // Performance issue: compiling regex on every call!
-        guard let regex = try? NSRegularExpression(pattern: pattern) else {
-            return nil
-        }
+        // Optimization: reuse pre-compiled regex
         let range = NSRange(input.startIndex..., in: input)
         guard regex.firstMatch(in: input, range: range) != nil else {
             return nil
         }
         
         let parameters: [String: String] = [:]
         // Extract named groups if any
         return parameters
     }
 }
```

**RouteParser.swift:**
```diff
 class RouteParser {
     private let matchers: [RouteMatcher]
     
     init() {
-        matchers = [
-            RouteMatcher(pattern: "^/home$", template: "/home"),
-            RouteMatcher(pattern: "^/profile$", template: "/profile"),
-            RouteMatcher(pattern: "^/settings$", template: "/settings"),
-            RouteMatcher(pattern: "^/feature/([^/]+)$", template: "/feature/:id"),
-            RouteMatcher(pattern: "^/help$", template: "/help"),
-        ]
+        // Optimization: pre-compile regex patterns once
+        let patterns = [
+            ("^/home$", "/home"),
+            ("^/profile$", "/profile"),
+            ("^/settings$", "/settings"),
+            ("^/feature/([^/]+)$", "/feature/:id"),
+            ("^/help$", "/help"),
+        ]
+        
+        matchers = patterns.compactMap { pattern, template in
+            guard let regex = try? NSRegularExpression(pattern: pattern) else {
+                assertionFailure("Invalid regex pattern: \(pattern)")
+                return nil
+            }
+            return RouteMatcher(regex: regex, template: template)
+        }
     }
```

**Reference:** See the full changes in [commit 1b3ece8](https://github.com/jhollida24/regex-performance/commit/1b3ece8b1c54a31de25cf43e2bb5acc614d3c3eb)

### Measuring the Improvement

> **[Profile again and record the improvement]**
> - Total parse time: ___ ms (was ___ ms)
> - Time in regex initialization: ___ ms (was ___ ms)
> - Reduction: ___%
> - Memory cost: ___ MB persistent

---

## Phase 5: Optimization #3 - Eliminate Duplicate Parsing

### The Theory

URLRedactor (`RegexPerformance/Redaction/URLRedactor.swift`) parses each URL twice. Collapse the capability check into the redact method and return a result enum indicating whether redaction was applicable.

### Working with the LLM

**Prompt 1: Planning**

```
URLRedactor (`RegexPerformance/Redaction/URLRedactor.swift`) parses 
each URL twice. Look at line 12—isCapableOfRedacting parses the URL. 
Then look at line 20—redact parses it again.

I want to remove isCapableOfRedacting and have redact() return an 
enum indicating success, not-applicable, or error. AggregateRedactor 
would try each redactor until one succeeds.

Show me your plan for refactoring this.
```

**LLM Response:**
[LLM outlines approach: new Result enum, remove method, update protocol, update aggregate logic]

**Prompt 2: Approval**

```
Go ahead and execute the plan.
```

**LLM Provides Protocol and Implementation**

**Prompt 3: Update Tests**

```
Update the tests in URLRedactorTests 
(`RegexPerformanceTests/URLRedactorTests.swift`) to work with the 
new Result-based API. Show me your plan first.
```

**LLM Response:**
[LLM outlines test changes]

**Prompt 4: Approval**

```
Go ahead and execute the plan.
```

**LLM Provides Updated Tests**

**Human Review and Commit**

### The Changes

**URLRedactor.swift:**
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
     private let parser = RouteParser()
     
-    func isCapableOfRedacting(urlString: String) -> Bool {
-        // Performance issue: parsing URL to check capability
-        return parser.parse(urlString) != nil
-    }
-    
-    func redact(urlString: String) -> String {
-        // Performance issue: parsing URL again to redact
+    func redact(urlString: String) -> RedactionResult {
+        // Optimization: parse once and return result
         guard let route = parser.parse(urlString) else {
-            return urlString
+            return .notApplicable
         }
-        return route.path
+        return .redacted(route.path)
     }
 }
```

**AggregateRedactor.swift:**
```diff
 class AggregateRedactor: URLRedactor {
     private let redactors: [URLRedactor]
     
     init(redactors: [URLRedactor]) {
         self.redactors = redactors
     }
     
-    func isCapableOfRedacting(urlString: String) -> Bool {
-        return redactors.contains { $0.isCapableOfRedacting(urlString: urlString) }
-    }
-    
-    func redact(urlString: String) -> String {
-        // Performance issue: checking capability then redacting
-        guard let redactor = redactors.first(where: { $0.isCapableOfRedacting(urlString: urlString) }) else {
-            return urlString
+    func redact(urlString: String) -> RedactionResult {
+        // Optimization: try each redactor until one succeeds
+        for redactor in redactors {
+            let result = redactor.redact(urlString: urlString)
+            if case .redacted = result {
+                return result
+            }
         }
-        return redactor.redact(urlString: urlString)
+        return .notApplicable
     }
 }
```

**Reference:** See the full changes in [commit 8011af7](https://github.com/jhollida24/regex-performance/commit/8011af73e5811e5901d6beededd91ea370cce45c)

### Measuring the Improvement

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
   - Use monospace for paths: `RegexPerformance/Routing/RouteMatcher.swift`
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

### Running the Same Test

**Critical: Use the Exact Same Test**
```
1. Launch the app
2. Tap "Feature Detail" button 5 times
3. Return to home
```

**Using Instruments Again:**
```bash
instruments -t "Time Profiler" -D trace_after.trace \
  -w <device-id> com.example.RegexPerformance

instruments -t "Allocations" -D allocations_after.trace \
  -w <device-id> com.example.RegexPerformance
```

### Summary of Improvements

> **[Your profiling results]**
> - Parse time: ___ ms → ___ ms (___% reduction)
> - Memory churn: ___ MB → ___ MB (___% reduction)
> - Memory cost: +___ MB persistent

**Reference:** See the final state in [commit 8011af7](https://github.com/jhollida24/regex-performance/commit/8011af73e5811e5901d6beededd91ea370cce45c)

---

## Conclusion: The Process

### What We Achieved

Three focused optimizations based on profile analysis:
1. Reused parsed routes in FeaturePresenter (eliminated redundant parsing)
2. Pre-compiled regex patterns in RouteMatcher (eliminated repeated compilation)
3. Removed duplicate parsing in URLRedactor (eliminated unnecessary work)

### The Process

1. **Measure** - Establish baseline with Instruments
2. **Analyze** - Use top-down and bottom-up views to understand the problem
3. **Theorize** - Form hypotheses about optimizations
4. **Implement** - Work with LLM: theory → plan → code → review
5. **Verify** - Measure with the same test scenario

### Why This Matters

These were three straightforward changes that:
- Were easy to review
- Had clear before/after metrics
- Fixed the reported bug
- Made a significant user-facing impact

### The Division of Labor

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

### Try It Yourself

```bash
git clone https://github.com/jhollida24/regex-performance
cd regex-performance
open RegexPerformance.xcodeproj
```

Build and profile the app yourself. Walk through each commit to see the optimizations.

Next time you get a performance bug:
1. Profile it with Instruments (save the trace!)
2. Analyze top-down and bottom-up views yourself
3. Form theories about the cause
4. Work with an LLM: state your theory, ask for a plan, then execute
5. Measure your results

The LLM is a coding assistant, not a performance analyst. You do the thinking, it does the typing.

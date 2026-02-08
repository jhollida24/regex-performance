# Debugging Performance with LLMs: Regex Optimization

A bug report came in: "Tapping the Feature Detail button is slow." This is a real issue I encountered in the Cash App codebase, generalized here for teaching. The problem turned out to be regex compilation happening repeatedly during route parsing—something that's easy to miss but has a significant performance impact.

This lesson demonstrates a systematic approach: measure the problem with Instruments, analyze the profile to understand what's happening, form theories about optimizations, and work with an LLM to implement the fixes. The repository is available for hands-on practice, so you can profile the initial state, apply each optimization, and measure the improvements yourself.

The techniques shown here apply directly to production codebases. I used this exact approach to fix the performance issue in Cash App, reducing parse time by 88% and memory churn by 87%.

---

## Phase 1: Measure the Problem

Before optimizing anything, I needed to establish a baseline. Without measurements, I'd be guessing about what's slow and whether my changes actually help.

The test scenario is straightforward:
1. Launch the app
2. Tap "Feature Detail" button
3. Tap "Simulate Updates" button (triggers 5 updates)
4. Observe the performance

To profile with Instruments:
- In Xcode: Product → Profile (Cmd+I)
- Choose "Time Profiler"
- Run the test scenario
- Stop recording
- **Save the trace file** (critical for comparison later)

I also profiled with the Allocations instrument to see memory churn. Both views are important—Time Profiler shows where time is spent, Allocations shows where memory is being allocated and deallocated repeatedly.

> **[Profile the app and record your baseline numbers here]**
> - Total parse time: ___ ms
> - Time in regex initialization: ___ ms
> - Main thread blocked: ___ ms
> - Memory churned: ___ MB

---

## Phase 2: Analyze the Profile

### Top-Down View

The top-down view in Instruments shows the call hierarchy—what calls what. I started by looking at main thread time and drilling down from high-level operations to low-level work.

The pattern I saw:
- UI update (button tap)
- Feature presenter update
- Route parsing
- Regex compilation

The "self time" column shows where actual work happens, not just where time is spent in child calls. NSRegularExpression initialization had significant self time, which meant the regex compilation itself was expensive.

### Bottom-Up View

The bottom-up view is where things got interesting. Instead of showing what calls what, it shows expensive operations and all the places they're called from.

I switched to bottom-up in Instruments and focused on NSRegularExpression.init. When I expanded it, I saw the same expensive operation being called from multiple places:
- FeaturePresenter.update()
- FeaturePresenter.logTap()
- FeaturePresenter.checkPermissions()
- RouteMatcher.matches() (called multiple times)
- RouteMatcher.extract() (called multiple times)

This revealed the core problem: repeated work.

### Forming Theories

Based on the profile analysis, I formed three theories:

**Theory 1**: FeaturePresenter parses the same route multiple times. The bottom-up view showed route parsing happening in update(), logTap(), and checkPermissions()—all for the same URL.

**Theory 2**: RouteMatcher compiles regex on every parse. The self time in NSRegularExpression.init was high, and it was being called repeatedly. Looking at the code confirmed it—patterns were stored as strings and compiled on every matches() and extract() call.

**Theory 3**: URLRedactor parses URL twice sequentially. The call stack showed isCapableOfRedacting() parsing a URL, immediately followed by redact() parsing the same URL again.

These theories came from analyzing the profile myself. The LLM doesn't do this analysis—I do the thinking, it does the implementation.

---

## Lesson 1: Reading Performance Profiles

Two views, two purposes:

**Top-Down**: Understand call hierarchy and follow expensive paths. Start from high-level operations (like UI updates) and drill down to find where time is actually spent. Use "self time" to identify methods doing actual work versus just calling other methods.

**Bottom-Up**: Find repeated work and identify optimization opportunities. Start from expensive operations (like NSRegularExpression.init) and expand to see all call sites. If the same expensive operation appears from multiple places, that's a candidate for caching or pre-computation.

When to use each:
- Top-down: "What's slow?"
- Bottom-up: "Why is it called so much?"

Patterns to spot:
- High self time: Actual expensive work
- Repeated calls: Same operation from multiple places
- Memory churn: Allocations happening repeatedly

---

## Phase 3: Optimization #1 - Cache Parsed Routes

Looking at FeaturePresenter, I saw the same route being parsed three times for one user interaction. The route doesn't change between these calls, so parsing it once and reusing the result should eliminate the redundant work.

Here's the prompt I used:

```
FeaturePresenter (`Sources/RegexPerformance/Presentation/FeaturePresenter.swift`) 
parses the same Route multiple times. Look at line 25—it parses when the 
feature updates. Then look at line 42—it parses again when logging. And 
line 58—parses again for permissions.

I want to parse once and reuse the result. Create an Action type that 
contains both the analytics event and the parsed Route.

Show me your plan for refactoring this.
```

The LLM's plan:
```
1. Create Action struct with feature and route fields
2. Add @Published currentAction property to FeaturePresenter
3. Parse route once in update() and store in currentAction
4. Reuse currentAction.route in logTap() and checkPermissions()
5. Ensure FeaturePresenter conforms to ObservableObject
```

I reviewed the plan, then said: "Go ahead and execute the plan."

The key changes:

```diff
 class FeaturePresenter: ObservableObject {
+    struct Action {
+        let feature: Feature
+        let route: Route?
+    }
+    
+    @Published var currentAction: Action?
+    
     func update(feature: Feature) {
-        let route = parser.parse(feature.url)
+        currentAction = Action(
+            feature: feature,
+            route: parser.parse(feature.url)
+        )
     }
     
     func logTap() {
-        let route = parser.parse(currentFeature.url)
+        guard let route = currentAction?.route else { return }
         analytics.log(event: .tap, route: route)
     }
     
     func checkPermissions() {
-        let route = parser.parse(currentFeature.url)
+        guard let route = currentAction?.route else { return }
         permissions.check(route: route)
     }
 }
```

[See the full changes in commit b9e44e7](../../commit/b9e44e7)

> **[Profile again and record the improvement]**
> - Total parse time: ___ ms (was ___ ms)
> - Reduction: ___%

---

## Phase 4: Optimization #2 - Pre-compile Regex Patterns

RouteMatcher stores regex patterns as strings and compiles them on every call to matches() and extract(). Profiling showed this accounts for about half of the total parse time. NSRegularExpression compilation is expensive—it parses the pattern, validates it, and optimizes it for matching.

I want to pre-compile the patterns once at initialization and store the NSRegularExpression instances instead of strings.

Here's the prompt:

```
RouteMatcher (`Sources/RegexPerformance/Routing/RouteMatcher.swift`) stores 
regex patterns as strings. Look at line 18—it compiles the regex on every 
call to matches(). Profiling shows this accounts for about half of the 
total parse time.

I want to pre-compile the patterns once at initialization. Store 
NSRegularExpression instances instead of strings.

Show me your plan for refactoring this.
```

The LLM's plan:
```
1. Change RouteMatcher.pattern from String to NSRegularExpression
2. Update RouteMatcher.init to accept NSRegularExpression
3. Remove regex compilation from matches() and extract() methods
4. Update RouteParser to compile patterns once at initialization
5. Handle compilation errors with compactMap
6. Verify NSRegularExpression is thread-safe for matching
```

I reviewed the plan, then said: "Go ahead and execute the plan."

The key changes in RouteMatcher:

```diff
 struct RouteMatcher {
-    let pattern: String
+    let regex: NSRegularExpression
     let parameterNames: [String]
     
-    init(pattern: String, parameterNames: [String]) {
-        self.pattern = pattern
+    init(regex: NSRegularExpression, parameterNames: [String]) {
+        self.regex = regex
         self.parameterNames = parameterNames
     }
     
     func matches(_ string: String) -> Bool {
-        guard let regex = try? NSRegularExpression(pattern: pattern) else {
-            return false
-        }
         let range = NSRange(string.startIndex..., in: string)
         return regex.firstMatch(in: string, range: range) != nil
     }
 }
```

And in RouteParser:

```diff
 class RouteParser {
     private let matchers: [RouteMatcher]
     
-    init(matchers: [RouteMatcher]) {
-        self.matchers = matchers
+    convenience init(patterns: [(pattern: String, parameterNames: [String])]) {
+        let matchers = patterns.compactMap { item -> RouteMatcher? in
+            guard let regex = try? NSRegularExpression(pattern: item.pattern) else {
+                return nil
+            }
+            return RouteMatcher(regex: regex, parameterNames: item.parameterNames)
+        }
+        self.init(matchers: matchers)
     }
 }
```

[See the full changes in commit bf4dee2](../../commit/bf4dee2)

This trades about 1MB of persistent memory (for the compiled regex instances) for eliminating the repeated compilation overhead. NSRegularExpression is thread-safe for matching, so this is safe to use from multiple threads.

> **[Profile again and record the improvement]**
> - Total parse time: ___ ms (was ___ ms)
> - Reduction: ___%
> - Memory cost: +___ MB persistent

---

## Phase 5: Optimization #3 - Eliminate Duplicate Parsing

URLRedactor has two methods: isCapableOfRedacting() and redact(). Both parse the URL. They're called sequentially on the same URL, which means the same parsing work happens twice in immediate succession.

I want to remove isCapableOfRedacting() and have redact() return an enum indicating whether redaction succeeded or the URL wasn't applicable.

Here's the prompt:

```
URLRedactor (`Sources/RegexPerformance/Redaction/URLRedactor.swift`) parses 
each URL twice. Look at line 12—isCapableOfRedacting parses the URL. Then 
look at line 20—redact parses it again.

I want to remove isCapableOfRedacting and have redact() return an enum 
indicating success, not-applicable, or error. AggregateRedactor would try 
each redactor until one succeeds.

Show me your plan for refactoring this.
```

The LLM's plan:
```
1. Add RedactionResult enum with .redacted(String) and .notApplicable cases
2. Remove isCapableOfRedacting from protocol
3. Change redact() return type to RedactionResult
4. Update ClientRouteURLRedactor to return appropriate result
5. Update AggregateRedactor to try each redactor until one succeeds
6. Update tests to check RedactionResult cases
```

I reviewed the plan, then said: "Go ahead and execute the plan."

The key changes in URLRedactor:

```diff
+public enum RedactionResult {
+    case redacted(String)
+    case notApplicable
+}
+
 public protocol URLRedactor {
-    func isCapableOfRedacting(urlString: String) -> Bool
-    func redact(urlString: String) -> String
+    func redact(urlString: String) -> RedactionResult
 }
 
 public class ClientRouteURLRedactor: URLRedactor {
-    public func isCapableOfRedacting(urlString: String) -> Bool {
-        return parser.parse(urlString) != nil
-    }
-    
-    public func redact(urlString: String) -> String {
+    public func redact(urlString: String) -> RedactionResult {
         guard let route = parser.parse(urlString) else {
-            return urlString
+            return .notApplicable
         }
         
         var redacted = route.path
         for (key, _) in route.parameters {
             redacted += "/\(key):<redacted>"
         }
         
-        return redacted
+        return .redacted(redacted)
     }
 }
```

And in AggregateRedactor:

```diff
 public class AggregateRedactor: URLRedactor {
-    public func isCapableOfRedacting(urlString: String) -> Bool {
-        return redactors.contains { $0.isCapableOfRedacting(urlString: urlString) }
-    }
-    
-    public func redact(urlString: String) -> String {
+    public func redact(urlString: String) -> RedactionResult {
         for redactor in redactors {
-            if redactor.isCapableOfRedacting(urlString: urlString) {
-                return redactor.redact(urlString: urlString)
+            let result = redactor.redact(urlString: urlString)
+            if case .redacted = result {
+                return result
             }
         }
-        return urlString
+        return .notApplicable
     }
 }
```

[See the full changes in commit e88e5dc](../../commit/e88e5dc)

This eliminates one full parse per redaction with no trade-offs. The API is also simpler—one method instead of two.

> **[Profile again and record the improvement]**
> - Total parse time: ___ ms (was ___ ms)
> - Reduction: ___%

---

## Lesson 2: Working with LLMs for Performance Optimization

The pattern I used for each optimization:

1. **State theory with file paths in monospace**: Point to specific files and line numbers
2. **Explain the problem**: What's happening and why it's slow
3. **Propose solution**: What to change
4. **Ask for a plan**: "Show me your plan for refactoring this."
5. **Review the plan**: Make sure it matches my theory
6. **Execute**: "Go ahead and execute the plan."
7. **Review the diff**: Examine the changes myself
8. **Commit or provide feedback**: If issues found, tell the LLM specifically what to fix

Example prompts from the optimizations:

```
FeaturePresenter (`Sources/RegexPerformance/Presentation/FeaturePresenter.swift`) 
parses the same Route multiple times. Look at line 25—it parses when the 
feature updates. Then look at line 42—it parses again when logging. And 
line 58—parses again for permissions.

I want to parse once and reuse the result. Create an Action type that 
contains both the analytics event and the parsed Route.

Show me your plan for refactoring this.
```

```
RouteMatcher (`Sources/RegexPerformance/Routing/RouteMatcher.swift`) stores 
regex patterns as strings. Look at line 18—it compiles the regex on every 
call to matches(). Profiling shows this accounts for about half of the 
total parse time.

I want to pre-compile the patterns once at initialization. Store 
NSRegularExpression instances instead of strings.

Show me your plan for refactoring this.
```

Division of labor:

**Human (me)**:
- Measures performance with Instruments
- Analyzes profiles (top-down and bottom-up views)
- Forms theories about what's slow and why
- Reasons through optimization approaches
- Decides on trade-offs
- Reviews generated code
- Verifies improvements through measurement

**LLM**:
- Implements refactorings based on my theories
- Generates boilerplate code
- Updates tests to match API changes
- Validates assumptions like thread-safety (in its plan)

**LLM does NOT**:
- Analyze performance profiles
- Form optimization theories
- Make architectural decisions
- Measure actual performance
- Decide on trade-offs

I use relative measurements in prompts ("about half the time") rather than exact numbers because your profiling results will differ from mine. The patterns and ratios are what matter, not the specific milliseconds.

---

## Phase 6: Measuring Results

After applying all three optimizations, I ran the same test scenario and profiled with Instruments again. Comparing the before and after traces showed significant improvements.

Example results from the Cash App codebase (your numbers will differ):

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Parse time | 485ms | 58ms | -88% |
| Regex init | 245ms | ~0ms | -100% |
| Memory churn | 70MB | 9MB | -87% |
| Persistent memory | baseline | +1MB | +1MB |

> **[Your profiling results]**
> - Parse time: ___ ms → ___ ms (___% reduction)
> - Memory churn: ___ MB → ___ MB (___% reduction)
> - Memory cost: +___ MB persistent

The biggest impact came from Optimization #2 (pre-compiling regex patterns). That single change eliminated the most expensive operation entirely. Optimization #1 reduced the number of times parsing happened, and Optimization #3 eliminated duplicate work.

The final state is in commit [e88e5dc](../../commit/e88e5dc).

---

## Conclusion

Three focused optimizations produced significant performance improvements:
- Reduced parse time by 88%
- Reduced memory churn by 87%
- Added only 1MB of persistent memory

The process:
1. Measure with Instruments
2. Analyze profiles yourself (top-down and bottom-up)
3. Form theories about what's slow and why
4. Work with LLM: theory → plan → execute → review
5. Verify improvements with measurement

These were straightforward changes—no complex algorithms or architectural rewrites. But they had a big user-facing impact. The "Tapping the Feature Detail button is slow" bug was fixed.

The techniques shown here apply to many codebases. Look for:
- Expensive operations called repeatedly
- Same work done multiple times
- Compilation or initialization happening in hot paths

Try it yourself:
1. Clone the repository
2. Check out commit [95d42e8](../../commit/95d42e8) (initial state)
3. Profile with Instruments
4. Walk through each optimization
5. Measure your own improvements

The LLM is a coding assistant, not a performance analyst. You do the thinking—analyzing profiles, forming theories, deciding on trade-offs. It does the typing—implementing refactorings, updating tests, generating boilerplate. That division of labor is what makes this approach effective.

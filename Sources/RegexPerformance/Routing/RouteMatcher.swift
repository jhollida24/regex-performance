import Foundation

/// Matches URLs against regex patterns
/// 
/// PERFORMANCE ISSUE: This compiles the regex on EVERY call to matches() and extract()
/// This is expensive and should be done once at initialization
public struct RouteMatcher {
    let pattern: String
    let template: String
    
    public init(pattern: String, template: String) {
        self.pattern = pattern
        self.template = template
    }
    
    /// Check if the input matches this route pattern
    /// PERFORMANCE ISSUE: Compiles regex on every call!
    public func matches(_ input: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return false
        }
        let range = NSRange(input.startIndex..., in: input)
        return regex.firstMatch(in: input, options: [], range: range) != nil
    }
    
    /// Extract parameters from the input if it matches
    /// PERFORMANCE ISSUE: Compiles regex on every call!
    public func extract(from input: String) -> [String: String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let range = NSRange(input.startIndex..., in: input)
        guard let _ = regex.firstMatch(in: input, options: [], range: range) else {
            return nil
        }
        
        // Simple parameter extraction (just for demo purposes)
        let parameters: [String: String] = [:]
        return parameters
    }
}

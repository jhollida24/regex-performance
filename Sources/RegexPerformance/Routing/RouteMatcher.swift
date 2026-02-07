import Foundation

/// Matches URLs against regex patterns
/// 
/// OPTIMIZED: Pre-compile the regex once and reuse it
public struct RouteMatcher {
    let regex: NSRegularExpression
    let template: String
    
    public init(regex: NSRegularExpression, template: String) {
        self.regex = regex
        self.template = template
    }
    
    /// Check if the input matches this route pattern
    /// OPTIMIZED: Reuse the pre-compiled regex
    public func matches(_ input: String) -> Bool {
        let range = NSRange(input.startIndex..., in: input)
        return regex.firstMatch(in: input, options: [], range: range) != nil
    }
    
    /// Extract parameters from the input if it matches
    /// OPTIMIZED: Reuse the pre-compiled regex
    public func extract(from input: String) -> [String: String]? {
        let range = NSRange(input.startIndex..., in: input)
        guard let _ = regex.firstMatch(in: input, options: [], range: range) else {
            return nil
        }
        
        // Simple parameter extraction (just for demo purposes)
        let parameters: [String: String] = [:]
        return parameters
    }
}

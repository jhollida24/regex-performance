import Foundation

/// Matches URL patterns using regular expressions
public struct RouteMatcher {
    public let pattern: String
    public let parameterNames: [String]
    
    public init(pattern: String, parameterNames: [String] = []) {
        self.pattern = pattern
        self.parameterNames = parameterNames
    }
    
    /// Check if the given path matches this pattern
    public func matches(_ path: String) -> Bool {
        // PERFORMANCE ISSUE: This compiles the regex on every call
        // Should pre-compile once and reuse
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        
        let range = NSRange(path.startIndex..., in: path)
        return regex.firstMatch(in: path, range: range) != nil
    }
    
    /// Extract parameters from the path if it matches
    public func extract(from path: String) -> [String: String]? {
        // PERFORMANCE ISSUE: This compiles the regex again on every call
        // Should pre-compile once and reuse
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        let range = NSRange(path.startIndex..., in: path)
        guard let match = regex.firstMatch(in: path, range: range) else {
            return nil
        }
        
        var parameters: [String: String] = [:]
        for (index, name) in parameterNames.enumerated() {
            let captureIndex = index + 1
            if captureIndex < match.numberOfRanges {
                let captureRange = match.range(at: captureIndex)
                if let range = Range(captureRange, in: path) {
                    parameters[name] = String(path[range])
                }
            }
        }
        
        return parameters
    }
}

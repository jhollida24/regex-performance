import Foundation

/// Matches URL patterns using regular expressions
public struct RouteMatcher {
    public let regex: NSRegularExpression
    public let parameterNames: [String]
    
    public init(regex: NSRegularExpression, parameterNames: [String] = []) {
        self.regex = regex
        self.parameterNames = parameterNames
    }
    
    /// Check if the given path matches this pattern
    public func matches(_ path: String) -> Bool {
        // OPTIMIZATION: Use pre-compiled regex instead of compiling on every call
        let range = NSRange(path.startIndex..., in: path)
        return regex.firstMatch(in: path, range: range) != nil
    }
    
    /// Extract parameters from the path if it matches
    public func extract(from path: String) -> [String: String]? {
        // OPTIMIZATION: Use pre-compiled regex instead of compiling on every call
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

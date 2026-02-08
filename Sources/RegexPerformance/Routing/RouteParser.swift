import Foundation

/// Parses URLs into Route objects using a set of matchers
public class RouteParser {
    private let matchers: [RouteMatcher]
    
    public init(matchers: [RouteMatcher]) {
        self.matchers = matchers
    }
    
    /// Convenience initializer that compiles patterns at initialization
    public convenience init(patterns: [(pattern: String, parameterNames: [String])]) {
        // OPTIMIZATION: Pre-compile all regex patterns once at initialization
        let matchers = patterns.compactMap { pattern, parameterNames -> RouteMatcher? in
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                print("Warning: Failed to compile regex pattern: \(pattern)")
                return nil
            }
            return RouteMatcher(regex: regex, parameterNames: parameterNames)
        }
        self.init(matchers: matchers)
    }
    
    /// Parse a URL string into a Route
    public func parse(_ urlString: String) -> Route? {
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        let path = url.path
        
        // Try each matcher until one matches
        for matcher in matchers {
            if matcher.matches(path) {
                let parameters = matcher.extract(from: path) ?? [:]
                return Route(path: path, parameters: parameters)
            }
        }
        
        return nil
    }
}

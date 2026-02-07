import Foundation

/// Parses URL strings into Route objects
public class RouteParser {
    private let matchers: [RouteMatcher]
    
    public init() {
        // OPTIMIZED: Pre-compile regex patterns once at initialization
        let patterns: [(String, String)] = [
            ("^/home$", "/home"),
            ("^/profile$", "/profile"),
            ("^/settings$", "/settings"),
            ("^/feature/([^/]+)$", "/feature/:id"),
            ("^/help$", "/help"),
        ]
        
        self.matchers = patterns.compactMap { pattern, template in
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return nil
            }
            return RouteMatcher(regex: regex, template: template)
        }
    }
    
    /// Parse a URL string into a Route
    /// OPTIMIZED: Uses pre-compiled regex patterns
    public func parse(_ urlString: String) -> Route? {
        for matcher in matchers {
            if matcher.matches(urlString) {
                let parameters = matcher.extract(from: urlString) ?? [:]
                return Route(path: urlString, parameters: parameters)
            }
        }
        return nil
    }
}

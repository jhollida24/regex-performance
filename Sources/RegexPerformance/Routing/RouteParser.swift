import Foundation

/// Parses URL strings into Route objects
public class RouteParser {
    private let matchers: [RouteMatcher]
    
    public init() {
        // Define route patterns
        // These patterns will be compiled on EVERY parse call (performance issue)
        self.matchers = [
            RouteMatcher(pattern: "^/home$", template: "/home"),
            RouteMatcher(pattern: "^/profile$", template: "/profile"),
            RouteMatcher(pattern: "^/settings$", template: "/settings"),
            RouteMatcher(pattern: "^/feature/([^/]+)$", template: "/feature/:id"),
            RouteMatcher(pattern: "^/help$", template: "/help"),
        ]
    }
    
    /// Parse a URL string into a Route
    /// This will compile 5+ regex patterns on EVERY call!
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

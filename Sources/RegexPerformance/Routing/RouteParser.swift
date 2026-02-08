import Foundation

/// Parses URLs into Route objects using a set of matchers
public class RouteParser {
    private let matchers: [RouteMatcher]
    
    public init(matchers: [RouteMatcher]) {
        self.matchers = matchers
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

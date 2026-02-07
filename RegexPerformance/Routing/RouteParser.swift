import Foundation

class RouteParser {
    private let matchers: [RouteMatcher]
    
    init() {
        // Optimization: compile regex patterns once at initialization
        self.matchers = [
            ("^/home$", "/home"),
            ("^/profile$", "/profile"),
            ("^/settings$", "/settings"),
            ("^/feature/([0-9]+)$", "/feature/:id"),
            ("^/help$", "/help"),
        ].compactMap { pattern, template in
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                assertionFailure("Invalid regex pattern: \(pattern)")
                return nil
            }
            return RouteMatcher(regex: regex, template: template)
        }
    }
    
    func parse(_ urlString: String) -> Route? {
        // Try each matcher - this will compile regex multiple times
        for matcher in matchers {
            if matcher.matches(urlString) {
                let parameters = matcher.extract(from: urlString) ?? [:]
                return Route(path: matcher.template, parameters: parameters)
            }
        }
        return nil
    }
}

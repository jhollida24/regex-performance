import Foundation

class RouteParser {
    private let matchers: [RouteMatcher]
    
    init() {
        // Define route patterns
        self.matchers = [
            RouteMatcher(pattern: "^/home$", template: "/home"),
            RouteMatcher(pattern: "^/profile$", template: "/profile"),
            RouteMatcher(pattern: "^/settings$", template: "/settings"),
            RouteMatcher(pattern: "^/feature/([0-9]+)$", template: "/feature/:id"),
            RouteMatcher(pattern: "^/help$", template: "/help"),
        ]
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

import Foundation

/// Protocol for URL redactors
public protocol URLRedactor {
    /// Check if this redactor can handle the given URL
    func isCapableOfRedacting(urlString: String) -> Bool
    
    /// Redact sensitive information from the URL
    func redact(urlString: String) -> String
}

/// Redacts URLs that match known client routes
public class ClientRouteURLRedactor: URLRedactor {
    private let parser: RouteParser
    
    public init(parser: RouteParser) {
        self.parser = parser
    }
    
    public func isCapableOfRedacting(urlString: String) -> Bool {
        // PERFORMANCE ISSUE: Parses the URL to check capability (first time)
        return parser.parse(urlString) != nil
    }
    
    public func redact(urlString: String) -> String {
        // PERFORMANCE ISSUE: Parses the same URL again (second time)
        guard let route = parser.parse(urlString) else {
            return urlString
        }
        
        // Redact parameter values
        var redacted = route.path
        for (key, _) in route.parameters {
            redacted += "/\(key):<redacted>"
        }
        
        return redacted
    }
}

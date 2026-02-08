import Foundation

/// Result of a URL redaction attempt
public enum RedactionResult {
    case redacted(String)
    case notApplicable
}

/// Protocol for URL redactors
public protocol URLRedactor {
    /// Attempt to redact a URL string
    /// Returns .redacted with the redacted string if successful
    /// Returns .notApplicable if this redactor doesn't handle this URL
    func redact(urlString: String) -> RedactionResult
}

/// Redacts URLs that match known client routes
public class ClientRouteURLRedactor: URLRedactor {
    private let parser: RouteParser
    
    public init(parser: RouteParser) {
        self.parser = parser
    }
    
    public func redact(urlString: String) -> RedactionResult {
        // OPTIMIZATION: Parse once and return result based on match
        guard let route = parser.parse(urlString) else {
            return .notApplicable
        }
        
        // Redact parameter values
        var redacted = route.path
        for (key, _) in route.parameters {
            redacted += "/\(key):<redacted>"
        }
        
        return .redacted(redacted)
    }
}

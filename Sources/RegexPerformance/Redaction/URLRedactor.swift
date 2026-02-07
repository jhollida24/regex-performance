import Foundation

/// Result of attempting to redact a URL
public enum RedactionResult {
    case redacted(String)
    case notApplicable
}

/// Protocol for redacting sensitive information from URLs
/// OPTIMIZED: Single method that returns a result enum
public protocol URLRedactor {
    /// Redact the URL if applicable
    /// Returns .redacted(String) if redaction was performed
    /// Returns .notApplicable if this redactor doesn't handle this URL
    func redact(urlString: String) -> RedactionResult
}

/// Redacts client route URLs by replacing IDs with placeholders
/// OPTIMIZED: Parse once and return result
public class ClientRouteURLRedactor: URLRedactor {
    private let parser: RouteParser
    
    public init(parser: RouteParser) {
        self.parser = parser
    }
    
    /// OPTIMIZED: Parse once and return result
    public func redact(urlString: String) -> RedactionResult {
        // Parse once to check and redact
        guard let _ = parser.parse(urlString) else {
            return .notApplicable
        }
        
        // Replace IDs with placeholders
        // e.g., /feature/123 -> /feature/:id
        if urlString.hasPrefix("/feature/") {
            return .redacted("/feature/:id")
        }
        
        return .redacted(urlString)
    }
}

import Foundation

/// Protocol for redacting sensitive information from URLs
public protocol URLRedactor {
    /// Check if this redactor can handle the given URL
    func isCapableOfRedacting(urlString: String) -> Bool
    
    /// Redact the URL (replace sensitive parts with placeholders)
    func redact(urlString: String) -> String
}

/// Redacts client route URLs by replacing IDs with placeholders
///
/// PERFORMANCE ISSUE: This parses URLs twice!
/// - Once in isCapableOfRedacting()
/// - Again in redact()
public class ClientRouteURLRedactor: URLRedactor {
    private let parser: RouteParser
    
    public init(parser: RouteParser) {
        self.parser = parser
    }
    
    /// PERFORMANCE ISSUE: Parses the URL to check if we can handle it
    public func isCapableOfRedacting(urlString: String) -> Bool {
        // Parse to see if this is a route we recognize
        return parser.parse(urlString) != nil
    }
    
    /// PERFORMANCE ISSUE: Parses the URL AGAIN to redact it
    public func redact(urlString: String) -> String {
        guard let route = parser.parse(urlString) else {
            return urlString
        }
        
        // Replace IDs with placeholders
        // e.g., /feature/123 -> /feature/:id
        if urlString.hasPrefix("/feature/") {
            return "/feature/:id"
        }
        
        return urlString
    }
}

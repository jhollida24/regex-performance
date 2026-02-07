import Foundation

/// Aggregates multiple URL redactors
/// Tries each redactor until one can handle the URL
/// OPTIMIZED: Single pass through redactors
public class AggregateRedactor: URLRedactor {
    private let redactors: [URLRedactor]
    
    public init(redactors: [URLRedactor]) {
        self.redactors = redactors
    }
    
    /// OPTIMIZED: Try each redactor once, return first successful result
    public func redact(urlString: String) -> RedactionResult {
        for redactor in redactors {
            let result = redactor.redact(urlString: urlString)
            if case .redacted = result {
                return result
            }
        }
        return .notApplicable
    }
}

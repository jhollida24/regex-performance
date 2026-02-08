import Foundation

/// Aggregates multiple URL redactors and tries them in sequence
public class AggregateRedactor: URLRedactor {
    private let redactors: [URLRedactor]
    
    public init(redactors: [URLRedactor]) {
        self.redactors = redactors
    }
    
    public func redact(urlString: String) -> RedactionResult {
        // OPTIMIZATION: Try each redactor until one succeeds
        // No separate capability check - just try to redact
        for redactor in redactors {
            let result = redactor.redact(urlString: urlString)
            if case .redacted = result {
                return result
            }
        }
        return .notApplicable
    }
}

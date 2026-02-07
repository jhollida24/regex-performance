import Foundation

/// Aggregates multiple URL redactors
/// Tries each redactor until one can handle the URL
public class AggregateRedactor: URLRedactor {
    private let redactors: [URLRedactor]
    
    public init(redactors: [URLRedactor]) {
        self.redactors = redactors
    }
    
    /// Check if any redactor can handle this URL
    /// PERFORMANCE ISSUE: This will cause each redactor to parse the URL
    public func isCapableOfRedacting(urlString: String) -> Bool {
        for redactor in redactors {
            if redactor.isCapableOfRedacting(urlString: urlString) {
                return true
            }
        }
        return false
    }
    
    /// Redact using the first capable redactor
    /// PERFORMANCE ISSUE: The URL was already parsed in isCapableOfRedacting!
    public func redact(urlString: String) -> String {
        for redactor in redactors {
            if redactor.isCapableOfRedacting(urlString: urlString) {
                return redactor.redact(urlString: urlString)
            }
        }
        return urlString
    }
}

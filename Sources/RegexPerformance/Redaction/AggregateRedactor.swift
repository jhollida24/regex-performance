import Foundation

/// Aggregates multiple URL redactors and tries them in sequence
public class AggregateRedactor: URLRedactor {
    private let redactors: [URLRedactor]
    
    public init(redactors: [URLRedactor]) {
        self.redactors = redactors
    }
    
    public func isCapableOfRedacting(urlString: String) -> Bool {
        return redactors.contains { $0.isCapableOfRedacting(urlString: urlString) }
    }
    
    public func redact(urlString: String) -> String {
        for redactor in redactors {
            if redactor.isCapableOfRedacting(urlString: urlString) {
                return redactor.redact(urlString: urlString)
            }
        }
        return urlString
    }
}

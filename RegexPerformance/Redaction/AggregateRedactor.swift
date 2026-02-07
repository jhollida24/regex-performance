import Foundation

class AggregateRedactor: URLRedactor {
    private let redactors: [URLRedactor]
    
    init(redactors: [URLRedactor]) {
        self.redactors = redactors
    }
    
    func redact(urlString: String) -> RedactionResult {
        // Optimization: try each redactor until one succeeds
        for redactor in redactors {
            let result = redactor.redact(urlString: urlString)
            if case .redacted = result {
                return result
            }
        }
        return .notApplicable
    }
}

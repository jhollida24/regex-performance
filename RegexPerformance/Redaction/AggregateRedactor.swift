import Foundation

class AggregateRedactor: URLRedactor {
    private let redactors: [URLRedactor]
    
    init(redactors: [URLRedactor]) {
        self.redactors = redactors
    }
    
    func isCapableOfRedacting(urlString: String) -> Bool {
        for redactor in redactors {
            if redactor.isCapableOfRedacting(urlString: urlString) {
                return true
            }
        }
        return false
    }
    
    func redact(urlString: String) -> String {
        for redactor in redactors {
            if redactor.isCapableOfRedacting(urlString: urlString) {
                return redactor.redact(urlString: urlString)
            }
        }
        return urlString
    }
}

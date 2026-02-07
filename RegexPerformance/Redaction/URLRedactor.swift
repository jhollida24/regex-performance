import Foundation

enum RedactionResult {
    case redacted(String)
    case notApplicable
}

protocol URLRedactor {
    func redact(urlString: String) -> RedactionResult
}

class ClientRouteURLRedactor: URLRedactor {
    private let parser = RouteParser()
    
    func redact(urlString: String) -> RedactionResult {
        // Optimization: parse once and return result
        guard let route = parser.parse(urlString) else {
            return .notApplicable
        }
        return .redacted(route.path)
    }
}

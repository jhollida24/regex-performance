import Foundation

protocol URLRedactor {
    func isCapableOfRedacting(urlString: String) -> Bool
    func redact(urlString: String) -> String
}

class ClientRouteURLRedactor: URLRedactor {
    private let parser = RouteParser()
    
    func isCapableOfRedacting(urlString: String) -> Bool {
        // Performance problem: parsing to check capability
        return parser.parse(urlString) != nil
    }
    
    func redact(urlString: String) -> String {
        // Performance problem: parsing again to redact
        guard let route = parser.parse(urlString) else {
            return urlString
        }
        
        // Redact sensitive parts
        return route.path
    }
}

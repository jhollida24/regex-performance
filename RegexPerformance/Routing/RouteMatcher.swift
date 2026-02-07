import Foundation

struct RouteMatcher {
    let regex: NSRegularExpression
    let template: String
    
    init(regex: NSRegularExpression, template: String) {
        self.regex = regex
        self.template = template
    }
    
    func matches(_ input: String) -> Bool {
        // Optimization: reuse pre-compiled regex
        let range = NSRange(input.startIndex..., in: input)
        return regex.firstMatch(in: input, range: range) != nil
    }
    
    func extract(from input: String) -> [String: String]? {
        // Optimization: reuse pre-compiled regex
        let range = NSRange(input.startIndex..., in: input)
        guard regex.firstMatch(in: input, range: range) != nil else {
            return nil
        }
        
        let parameters: [String: String] = [:]
        // Extract named groups if any
        return parameters
    }
}

import Foundation

struct RouteMatcher {
    let pattern: String
    let template: String
    
    init(pattern: String, template: String) {
        self.pattern = pattern
        self.template = template
    }
    
    func matches(_ input: String) -> Bool {
        // This is the performance problem: compiling regex on every call
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return false
        }
        let range = NSRange(input.startIndex..., in: input)
        return regex.firstMatch(in: input, range: range) != nil
    }
    
    func extract(from input: String) -> [String: String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        let range = NSRange(input.startIndex..., in: input)
        guard let match = regex.firstMatch(in: input, range: range) else {
            return nil
        }
        
        var parameters: [String: String] = [:]
        // Extract named groups if any
        return parameters
    }
}

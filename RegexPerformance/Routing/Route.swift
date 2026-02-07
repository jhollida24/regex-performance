import Foundation

struct Route: Equatable {
    let path: String
    let parameters: [String: String]
    
    init(path: String, parameters: [String: String] = [:]) {
        self.path = path
        self.parameters = parameters
    }
}

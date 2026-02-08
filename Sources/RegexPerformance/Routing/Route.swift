import Foundation

/// Represents a parsed route with path and extracted parameters
public struct Route: Equatable {
    public let path: String
    public let parameters: [String: String]
    
    public init(path: String, parameters: [String: String] = [:]) {
        self.path = path
        self.parameters = parameters
    }
}

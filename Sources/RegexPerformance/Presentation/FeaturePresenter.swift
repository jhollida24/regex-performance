import Foundation
import Combine

/// Presents feature information to the UI
///
/// PERFORMANCE ISSUE: This parses the same route multiple times!
/// - Once in update()
/// - Again in logTap()
/// - Again in checkPermissions()
public class FeaturePresenter: ObservableObject {
    private let parser: RouteParser
    private var currentFeature: Feature?
    
    public struct Feature {
        public let id: String
        public let name: String
        public let url: String
        
        public init(id: String, name: String, url: String) {
            self.id = id
            self.name = name
            self.url = url
        }
    }
    
    public init(parser: RouteParser) {
        self.parser = parser
    }
    
    /// Update with a new feature
    /// PERFORMANCE ISSUE: Parses the route here
    public func update(feature: Feature) {
        self.currentFeature = feature
        
        // Parse the route to get route information
        let route = parser.parse(feature.url)
        
        // Use the route for something...
        if let route = route {
            print("Updated to feature at path: \(route.path)")
        }
    }
    
    /// Log a tap event
    /// PERFORMANCE ISSUE: Parses the SAME route again!
    public func logTap() {
        guard let feature = currentFeature else { return }
        
        // Parse the route again to log it
        let route = parser.parse(feature.url)
        
        if let route = route {
            print("Logged tap on: \(route.path)")
        }
    }
    
    /// Check permissions for the current feature
    /// PERFORMANCE ISSUE: Parses the SAME route yet again!
    public func checkPermissions() {
        guard let feature = currentFeature else { return }
        
        // Parse the route again to check permissions
        let route = parser.parse(feature.url)
        
        if let route = route {
            print("Checked permissions for: \(route.path)")
        }
    }
}

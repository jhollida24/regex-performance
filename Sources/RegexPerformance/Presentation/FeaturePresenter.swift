import Foundation
import Combine

/// Presents feature information to the UI
///
/// OPTIMIZED: Parse route once and reuse it!
public class FeaturePresenter: ObservableObject {
    private let parser: RouteParser
    private var currentAction: Action?
    
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
    
    /// Action bundles the feature with its parsed route
    /// OPTIMIZED: Parse once, reuse many times
    public struct Action {
        public let feature: Feature
        public let route: Route?
        
        public init(feature: Feature, route: Route?) {
            self.feature = feature
            self.route = route
        }
    }
    
    public init(parser: RouteParser) {
        self.parser = parser
    }
    
    /// Update with a new feature
    /// OPTIMIZED: Parse once and store in Action
    public func update(feature: Feature) {
        // Parse the route once
        let route = parser.parse(feature.url)
        
        // Store both feature and route together
        self.currentAction = Action(feature: feature, route: route)
        
        // Use the route for something...
        if let route = route {
            print("Updated to feature at path: \(route.path)")
        }
    }
    
    /// Log a tap event
    /// OPTIMIZED: Reuse the parsed route from currentAction
    public func logTap() {
        guard let action = currentAction else { return }
        
        // Reuse the already-parsed route
        if let route = action.route {
            print("Logged tap on: \(route.path)")
        }
    }
    
    /// Check permissions for the current feature
    /// OPTIMIZED: Reuse the parsed route from currentAction
    public func checkPermissions() {
        guard let action = currentAction else { return }
        
        // Reuse the already-parsed route
        if let route = action.route {
            print("Checked permissions for: \(route.path)")
        }
    }
}

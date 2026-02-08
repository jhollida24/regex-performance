import Foundation
import Combine

/// Presents feature state and handles user interactions
public class FeaturePresenter: ObservableObject {
    public struct Feature {
        public let id: String
        public let url: String
        
        public init(id: String, url: String) {
            self.id = id
            self.url = url
        }
    }
    
    /// Action bundles a feature with its parsed route
    public struct Action {
        public let feature: Feature
        public let route: Route?
    }
    
    private let parser: RouteParser
    @Published public var currentFeature: Feature?
    @Published public var currentAction: Action?
    
    public init(parser: RouteParser) {
        self.parser = parser
    }
    
    /// Update the current feature
    public func update(feature: Feature) {
        // OPTIMIZATION: Parse once and store in Action
        let route = parser.parse(feature.url)
        currentAction = Action(feature: feature, route: route)
        print("Feature updated: \(feature.id), route: \(route?.path ?? "none")")
        currentFeature = feature
    }
    
    /// Log a tap event for analytics
    public func logTap() {
        guard let action = currentAction else { return }
        
        // OPTIMIZATION: Reuse the parsed route from currentAction
        print("Analytics: tap on \(action.feature.id), route: \(action.route?.path ?? "none")")
    }
    
    /// Check permissions for the current feature
    public func checkPermissions() -> Bool {
        guard let action = currentAction else { return false }
        
        // OPTIMIZATION: Reuse the parsed route from currentAction
        print("Checking permissions for \(action.feature.id), route: \(action.route?.path ?? "none")")
        
        // Simple permission check based on route
        return action.route != nil
    }
}

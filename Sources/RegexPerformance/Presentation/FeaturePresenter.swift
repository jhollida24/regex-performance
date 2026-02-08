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
    
    private let parser: RouteParser
    @Published public var currentFeature: Feature?
    
    public init(parser: RouteParser) {
        self.parser = parser
    }
    
    /// Update the current feature
    public func update(feature: Feature) {
        // PERFORMANCE ISSUE: Parses the route here (first time)
        let route = parser.parse(feature.url)
        print("Feature updated: \(feature.id), route: \(route?.path ?? "none")")
        currentFeature = feature
    }
    
    /// Log a tap event for analytics
    public func logTap() {
        guard let feature = currentFeature else { return }
        
        // PERFORMANCE ISSUE: Parses the same route again (second time)
        let route = parser.parse(feature.url)
        print("Analytics: tap on \(feature.id), route: \(route?.path ?? "none")")
    }
    
    /// Check permissions for the current feature
    public func checkPermissions() -> Bool {
        guard let feature = currentFeature else { return false }
        
        // PERFORMANCE ISSUE: Parses the same route again (third time)
        let route = parser.parse(feature.url)
        print("Checking permissions for \(feature.id), route: \(route?.path ?? "none")")
        
        // Simple permission check based on route
        return route != nil
    }
}

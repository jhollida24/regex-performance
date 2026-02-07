import Foundation
import Combine

class FeaturePresenter: ObservableObject {
    @Published var model: FeatureModel?
    
    private let parser = RouteParser()
    private var cancellables = Set<AnyCancellable>()
    
    struct Feature {
        let id: String
        let url: String
        let title: String
    }
    
    struct Action {
        let feature: Feature
        let route: Route?
        
        var requiresPermissions: Bool {
            route?.path.contains("feature") ?? false
        }
    }
    
    struct FeatureModel {
        let feature: Feature
        let route: Route?
    }
    
    private var currentAction: Action?
    
    init() {
        // Simulate feature updates
    }
    
    func update(feature: Feature) {
        // Optimization: parse once and store in Action
        let route = parser.parse(feature.url)
        let action = Action(feature: feature, route: route)
        currentAction = action
        model = FeatureModel(feature: feature, route: route)
    }
    
    func logTap() {
        // Optimization: reuse the parsed route from currentAction
        guard let action = currentAction else { return }
        print("Analytics: Tapped feature with route \(action.route?.path ?? "unknown")")
    }
    
    func checkPermissions() -> Bool {
        // Optimization: reuse the parsed route from currentAction
        guard let action = currentAction else { return false }
        return action.requiresPermissions
    }
}

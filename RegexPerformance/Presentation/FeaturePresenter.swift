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
    
    struct FeatureModel {
        let feature: Feature
        let route: Route?
    }
    
    init() {
        // Simulate feature updates
    }
    
    func update(feature: Feature) {
        // Performance problem: parsing on every update
        let route = parser.parse(feature.url)
        model = FeatureModel(feature: feature, route: route)
    }
    
    func logTap(feature: Feature) {
        // Performance problem: parsing again for logging
        let route = parser.parse(feature.url)
        print("Analytics: Tapped feature with route \(route?.path ?? "unknown")")
    }
    
    func checkPermissions(feature: Feature) -> Bool {
        // Performance problem: parsing again for permissions
        let route = parser.parse(feature.url)
        // Check if route requires special permissions
        return route?.path.contains("feature") ?? false
    }
}

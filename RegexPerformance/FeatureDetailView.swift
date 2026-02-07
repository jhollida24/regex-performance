import SwiftUI

struct FeatureDetailView: View {
    @StateObject private var presenter = FeaturePresenter()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Feature Detail")
                .font(.largeTitle)
            
            if let model = presenter.model {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Feature: \(model.feature.title)")
                    Text("URL: \(model.feature.url)")
                    if let route = model.route {
                        Text("Route: \(route.path)")
                    }
                }
                .padding()
            }
            
            Button("Simulate Updates") {
                // Simulate multiple feature updates to trigger repeated parsing
                for i in 1...10 {
                    let feature = FeaturePresenter.Feature(
                        id: "\(i)",
                        url: "/feature/\(i)",
                        title: "Feature \(i)"
                    )
                    presenter.update(feature: feature)
                    presenter.logTap()
                    _ = presenter.checkPermissions()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            let feature = FeaturePresenter.Feature(
                id: "123",
                url: "/feature/123",
                title: "Example Feature"
            )
            presenter.update(feature: feature)
        }
    }
}

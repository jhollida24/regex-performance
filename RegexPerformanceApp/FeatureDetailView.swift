import SwiftUI
import RegexPerformance

struct FeatureDetailView: View {
    @ObservedObject var presenter: FeaturePresenter
    @State private var updateCount = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Feature Detail")
                .font(.title)
            
            if let feature = presenter.currentFeature {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Feature ID: \(feature.id)")
                        .font(.headline)
                    Text("URL: \(feature.url)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            
            Button(action: simulateUpdates) {
                VStack {
                    Text("Simulate Updates")
                        .font(.headline)
                    Text("Triggers 5 feature updates")
                        .font(.caption)
                    Text("(Each parses route 3 times)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            
            Text("Updates triggered: \(updateCount)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Feature Detail")
    }
    
    private func simulateUpdates() {
        // Simulate 5 rapid feature updates
        // Each update causes 3 route parses (update, log, permissions)
        for i in 1...5 {
            let feature = FeaturePresenter.Feature(
                id: "feature-\(i)",
                url: "https://example.com/feature/\(i)"
            )
            presenter.update(feature: feature)
            presenter.logTap()
            _ = presenter.checkPermissions()
            updateCount += 1
        }
    }
}

#Preview {
    let matchers = [
        RouteMatcher(pattern: "^/feature/([^/]+)$", parameterNames: ["id"])
    ]
    let parser = RouteParser(matchers: matchers)
    let presenter = FeaturePresenter(parser: parser)
    
    return FeatureDetailView(presenter: presenter)
}

import SwiftUI

struct FeatureDetailView: View {
    @StateObject private var presenter = FeaturePresenter(parser: RouteParser())
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Feature Detail")
                    .font(.largeTitle)
                
                Text("This view demonstrates the performance issue.")
                    .foregroundColor(.secondary)
                    .padding()
                
                Button("Simulate Updates") {
                    // Simulate multiple feature updates
                    // This will trigger the redundant parsing
                    for i in 1...5 {
                        let feature = FeaturePresenter.Feature(
                            id: "\(i)",
                            name: "Feature \(i)",
                            url: "/feature/\(i)"
                        )
                        presenter.update(feature: feature)
                        presenter.logTap()
                        presenter.checkPermissions()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

import SwiftUI

struct ContentView: View {
    @State private var selectedRoute: String?
    @State private var navigateToFeature = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Route Performance Demo")
                    .font(.largeTitle)
                    .padding()
                
                VStack(spacing: 15) {
                    Button("Home") {
                        selectedRoute = "/home"
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Profile") {
                        selectedRoute = "/profile"
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Settings") {
                        selectedRoute = "/settings"
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Feature Detail") {
                        selectedRoute = "/feature/123"
                        navigateToFeature = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Help") {
                        selectedRoute = "/help"
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if let route = selectedRoute {
                    Text("Selected: \(route)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .navigationDestination(isPresented: $navigateToFeature) {
                FeatureDetailView()
            }
        }
    }
}

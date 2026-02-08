import SwiftUI

struct ContentView: View {
    @State private var selectedRoute: String?
    @State private var showingDetail = false
    
    var body: some View {
        NavigationView {
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
                        showingDetail = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Help") {
                        selectedRoute = "/help"
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
                if let route = selectedRoute {
                    Text("Selected: \(route)")
                        .foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $showingDetail) {
                FeatureDetailView()
            }
        }
    }
}

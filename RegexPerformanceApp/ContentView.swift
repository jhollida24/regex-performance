import SwiftUI
import RegexPerformance

struct ContentView: View {
    @StateObject private var presenter: FeaturePresenter
    
    init() {
        // Create route matchers for common patterns
        let matchers = [
            RouteMatcher(pattern: "^/home$", parameterNames: []),
            RouteMatcher(pattern: "^/profile$", parameterNames: []),
            RouteMatcher(pattern: "^/settings$", parameterNames: []),
            RouteMatcher(pattern: "^/feature/([^/]+)$", parameterNames: ["id"]),
            RouteMatcher(pattern: "^/help$", parameterNames: [])
        ]
        let parser = RouteParser(matchers: matchers)
        _presenter = StateObject(wrappedValue: FeaturePresenter(parser: parser))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Regex Performance Demo")
                    .font(.title)
                    .padding()
                
                Text("Tap buttons to navigate and trigger route parsing")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 15) {
                    NavigationLink(destination: Text("Home")) {
                        RouteButton(title: "Home", route: "/home")
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        handleTap(id: "home", url: "https://example.com/home")
                    })
                    
                    NavigationLink(destination: Text("Profile")) {
                        RouteButton(title: "Profile", route: "/profile")
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        handleTap(id: "profile", url: "https://example.com/profile")
                    })
                    
                    NavigationLink(destination: Text("Settings")) {
                        RouteButton(title: "Settings", route: "/settings")
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        handleTap(id: "settings", url: "https://example.com/settings")
                    })
                    
                    NavigationLink(destination: FeatureDetailView(presenter: presenter)) {
                        RouteButton(title: "Feature Detail", route: "/feature/123", highlighted: true)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        handleTap(id: "feature-123", url: "https://example.com/feature/123")
                    })
                    
                    NavigationLink(destination: Text("Help")) {
                        RouteButton(title: "Help", route: "/help")
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        handleTap(id: "help", url: "https://example.com/help")
                    })
                }
                .padding()
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
    
    private func handleTap(id: String, url: String) {
        let feature = FeaturePresenter.Feature(id: id, url: url)
        presenter.update(feature: feature)
        presenter.logTap()
        _ = presenter.checkPermissions()
    }
}

struct RouteButton: View {
    let title: String
    let route: String
    var highlighted: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(route)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(highlighted ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    ContentView()
}

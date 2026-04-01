import SwiftUI

@available(macOS 11.0, *)
struct ContentView: View {
    var body: some View {
        DashboardView()
    }
}

#if os(iOS)
@available(iOS 16.0, *)
#Preview {
    ContentView()
}
#endif
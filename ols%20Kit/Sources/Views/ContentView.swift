import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "swift")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
                Text("Tools Kit")
                    .font(.largeTitle.bold())
                Text("Built with SwiftCode")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Tools Kit")
        }
    }
}

#Preview {
    ContentView()
}
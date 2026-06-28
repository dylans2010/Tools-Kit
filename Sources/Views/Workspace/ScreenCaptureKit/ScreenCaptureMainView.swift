#if canImport(ScreenCaptureKit)

import SwiftUI


@available(iOS 27.0, *)
struct ScreenCaptureMainView: View {
    @State private var showingSettings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                SCKDashboardSection(title: "Recording & Capture") {
                    SCKDashboardCards.recordingAndCapture
                }

                SCKDashboardSection(title: "Professional & Study") {
                    SCKDashboardCards.professionalAndStudy
                }

                SCKDashboardSection(title: "Utilities & Insights") {
                    SCKDashboardCards.utilitiesAndInsights
                }
            }
            .padding()
        }
        .navigationTitle("Screen Capture")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SCKSettingsView()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Intelligent Capture")
                .font(.title2.bold())
            Text("Capture, transcribe, and analyze your screen with AI.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

@available(iOS 27.0, *)
struct SCKDashboardSection<Content: View>: View {
    let title: String
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                content()
            }
        }
    }
}

#Preview {
    NavigationStack {
        if #available(iOS 27.0, *) {
            ScreenCaptureMainView()
        } else {
            // Fallback on earlier versions
        }
    }
}


#endif

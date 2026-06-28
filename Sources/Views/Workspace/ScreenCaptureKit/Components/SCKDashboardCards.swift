import SwiftUI

struct SCKDashboardCards {
    @ViewBuilder
    static var recordingAndCapture: some View {
        SCKCard(
            title: "AI Capture",
            icon: "sparkles.tv",
            color: .purple,
            destination: AICaptureView()
        )
        SCKCard(
            title: "Screen Recorder",
            icon: "record.circle",
            color: .red,
            destination: SCKScreenRecorderView()
        )
        SCKCard(
            title: "Smart Screenshot",
            icon: "viewfinder",
            color: .blue,
            destination: SmartScreenshotView()
        )
        SCKCard(
            title: "OCR Scanner",
            icon: "text.viewfinder",
            color: .orange,
            destination: OCRScannerView()
        )
    }

    @ViewBuilder
    static var professionalAndStudy: some View {
        SCKCard(
            title: "Meeting Recorder",
            icon: "video.badge.plus",
            color: .green,
            destination: MeetingRecorderView()
        )
        SCKCard(
            title: "Presentation Recorder",
            icon: "rectangle.inset.filled.and.person.filled",
            color: .indigo,
            destination: PresentationRecorderView()
        )
        SCKCard(
            title: "Study Mode",
            icon: "book.closed.fill",
            color: .brown,
            destination: StudyModeView()
        )
        SCKCard(
            title: "Tutorial Creator",
            icon: "graduationcap.fill",
            color: .teal,
            destination: TutorialCreatorView()
        )
    }

    @ViewBuilder
    static var utilitiesAndInsights: some View {
        SCKCard(
            title: "Bug Reporter",
            icon: "ladybug.fill",
            color: .red,
            destination: SCKBugReporterView()
        )
        SCKCard(
            title: "Search",
            icon: "magnifyingglass",
            color: .gray,
            destination: SCKSearchView()
        )
        SCKCard(
            title: "Timeline",
            icon: "clock.arrow.circlepath",
            color: .cyan,
            destination: SCKTimelineView()
        )
        SCKCard(
            title: "Workspace Gen",
            icon: "square.stack.3d.up.fill",
            color: .mint,
            destination: SCKWorkspaceGeneratorView()
        )
        SCKCard(
            title: "Analytics",
            icon: "chart.bar.fill",
            color: .pink,
            destination: SCKAnalyticsView()
        )
        SCKCard(
            title: "Settings",
            icon: "gearshape.fill",
            color: .secondary,
            destination: SCKSettingsView()
        )
    }
}

struct SCKCard<Destination: View>: View {
    let title: String
    let icon: String
    let color: Color
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(color)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

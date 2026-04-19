import SwiftUI
import UIKit

struct CreateMeetingView: View {
    @ObservedObject var controller: MeetSessionController
    @Environment(\.dismiss) private var dismiss
    @State private var meetingName = ""
    @State private var showingSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                VStack(alignment: .leading, spacing: 12) {
                    Text("Meeting Name")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)

                    TextField("Project Sync, Weekly Catchup...", text: $meetingName)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal)

                if let session = controller.currentSession {
                    successState(session: session)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    createButton
                }

                Spacer()
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("New Meeting")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .fontWeight(.bold)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "video.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))

            Text("Create a Secure Meeting")
                .font(.title2.bold())

            Text("Your meeting ID will be automatically generated and encrypted for your security.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top)
    }

    private var createButton: some View {
        Button {
            Task {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                await controller.createMeeting(name: meetingName)
                withAnimation(.spring()) {
                    showingSuccess = true
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } label: {
            HStack {
                if controller.isBusy {
                    ProgressView()
                        .tint(.white)
                        .padding(.trailing, 8)
                }
                Text(controller.isBusy ? "Generating ID..." : "Create Meeting")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(meetingName.isEmpty ? Color.gray : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(14)
            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(meetingName.isEmpty || controller.isBusy)
        .padding(.horizontal)
        .overlay {
            if controller.isBusy {
                shimmerOverlay
            }
        }
    }

    private var shimmerOverlay: some View {
        Color.white.opacity(0.1)
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(gradient: Gradient(colors: [.clear, .white.opacity(0.5), .clear]), startPoint: .leading, endPoint: .trailing)
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: controller.isBusy ? 400 : -400)
            )
            .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: controller.isBusy)
    }

    private func successState(session: MeetingSession) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(.green)
                .symbolEffect(.bounce, value: showingSuccess)

            VStack(spacing: 8) {
                Text("Meeting Ready!")
                    .font(.headline)

                Text("Share this encrypted ID with participants:")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let encryptedID = controller.persistedMeetings.last?.encryptedID {
                HStack {
                    Text(encryptedID)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button {
                        UIPasteboard.general.string = encryptedID
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.accentColor)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.accentColor.opacity(0.1), lineWidth: 1))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
}

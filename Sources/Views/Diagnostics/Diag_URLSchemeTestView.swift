import SwiftUI
import UIKit

struct Diag_URLSchemeTestView: View {
    @State private var customScheme: String = ""
    @State private var testResults: [SchemeTestResult] = []
    @State private var isTesting = false

    struct SchemeTestResult: Identifiable {
        let id = UUID()
        let scheme: String
        let appName: String
        let canOpen: Bool
        let timestamp: Date
    }

    private let commonSchemes: [(String, String, String)] = [
        ("tel://", "Phone", "phone.fill"),
        ("sms://", "Messages", "message.fill"),
        ("mailto://", "Mail", "envelope.fill"),
        ("facetime://", "FaceTime", "video.fill"),
        ("maps://", "Maps", "map.fill"),
        ("music://", "Music", "music.note"),
        ("itms-apps://", "App Store", "bag.fill"),
        ("app-settings://", "Settings", "gear"),
        ("shortcuts://", "Shortcuts", "square.stack.3d.up.fill"),
        ("photos-redirect://", "Photos", "photo.fill"),
        ("x-apple-health://", "Health", "heart.fill"),
        ("calshow://", "Calendar", "calendar"),
        ("x-apple-reminder://", "Reminders", "checklist"),
        ("safari-https://", "Safari", "safari.fill"),
        ("files://", "Files", "folder.fill"),
        ("nflx://", "Netflix", "play.tv.fill"),
        ("twitter://", "X (Twitter)", "bubble.left.fill"),
        ("instagram://", "Instagram", "camera.fill"),
        ("fb://", "Facebook", "person.2.fill"),
        ("whatsapp://", "WhatsApp", "phone.bubble.fill"),
        ("spotify://", "Spotify", "music.note.list"),
        ("youtube://", "YouTube", "play.rectangle.fill"),
        ("slack://", "Slack", "number"),
        ("tg://", "Telegram", "paperplane.fill"),
    ]

    var body: some View {
        Form {
            Section("Custom Test") {
                HStack {
                    TextField("URL Scheme (e.g., myapp://)", text: $customScheme)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    Button("Test") {
                        testCustomScheme()
                    }
                    .disabled(customScheme.isEmpty)
                }
            }

            Section("System Apps") {
                ForEach(commonSchemes.prefix(15), id: \.0) { scheme, name, icon in
                    HStack {
                        Image(systemName: icon)
                            .font(.body)
                            .frame(width: 28)
                            .foregroundStyle(.blue)
                        Text(name)
                        Spacer()
                        Text(scheme)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        if let result = testResults.first(where: { $0.scheme == scheme }) {
                            Image(systemName: result.canOpen ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result.canOpen ? .green : .red)
                        }
                    }
                }
            }

            Section("Third Party Apps") {
                ForEach(commonSchemes.suffix(9), id: \.0) { scheme, name, icon in
                    HStack {
                        Image(systemName: icon)
                            .font(.body)
                            .frame(width: 28)
                            .foregroundStyle(.purple)
                        Text(name)
                        Spacer()
                        Text(scheme)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        if let result = testResults.first(where: { $0.scheme == scheme }) {
                            Image(systemName: result.canOpen ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result.canOpen ? .green : .red)
                        }
                    }
                }
            }

            Section {
                Button {
                    testAllSchemes()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text(isTesting ? "Testing..." : "Test All Schemes")
                    }
                }
                .disabled(isTesting)
            }

            if !testResults.isEmpty {
                Section("Results Summary") {
                    let available = testResults.filter(\.canOpen).count
                    let total = testResults.count
                    LabeledContent("Available") {
                        Text("\(available) / \(total)")
                            .foregroundStyle(.green)
                    }
                    LabeledContent("Not Installed") {
                        Text("\(total - available) / \(total)")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("URL Scheme Tester")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func testCustomScheme() {
        let scheme = customScheme.hasSuffix("://") ? customScheme : customScheme + "://"
        if let url = URL(string: scheme) {
            let canOpen = UIApplication.shared.canOpenURL(url)
            testResults.insert(
                SchemeTestResult(scheme: scheme, appName: "Custom", canOpen: canOpen, timestamp: Date()),
                at: 0
            )
        }
    }

    private func testAllSchemes() {
        isTesting = true
        testResults = []

        DispatchQueue.global(qos: .userInitiated).async {
            for (scheme, name, _) in commonSchemes {
                if let url = URL(string: scheme) {
                    DispatchQueue.main.async {
                        let canOpen = UIApplication.shared.canOpenURL(url)
                        testResults.append(
                            SchemeTestResult(scheme: scheme, appName: name, canOpen: canOpen, timestamp: Date())
                        )
                    }
                }
                Thread.sleep(forTimeInterval: 0.05)
            }
            DispatchQueue.main.async { isTesting = false }
        }
    }
}

import SwiftUI

struct WiFiTransferView: View {
    @StateObject private var server = WiFiTransferServer.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    statusCard
                    if server.isRunning {
                        connectionInfoCard
                        instructionsCard
                        logCard
                    }
                }
                .padding()
            }
            .navigationTitle("WiFi Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onDisappear {
                server.stop()
            }
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(server.isRunning ? Color.green.opacity(0.15) : Color(.systemGray5))
                    .frame(width: 80, height: 80)
                Image(systemName: server.isRunning ? "wifi" : "wifi.slash")
                    .font(.system(size: 36))
                    .foregroundColor(server.isRunning ? .green : .secondary)
            }

            Text(server.isRunning ? "Server Active" : "Server Stopped")
                .font(.title3.bold())

            Button {
                if server.isRunning { server.stop() } else { server.start() }
            } label: {
                Text(server.isRunning ? "Stop Server" : "Start Server")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(server.isRunning ? Color.red : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Connection Info

    private var connectionInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Connection Info", systemImage: "info.circle")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Address").font(.caption).foregroundColor(.secondary)
                    Text("http://\(server.ipAddress):\(server.port)")
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = "http://\(server.ipAddress):\(server.port)"
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.accentColor)
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pairing Code").font(.caption).foregroundColor(.secondary)
                    Text(server.pairingCode)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .tracking(8)
                        .foregroundColor(.accentColor)
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = server.pairingCode
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Instructions

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("How to Transfer", systemImage: "questionmark.circle")
                .font(.headline)

            instructionStep(number: "1", text: "Open a browser on your computer")
            instructionStep(number: "2", text: "Navigate to http://\(server.ipAddress):\(server.port)")
            instructionStep(number: "3", text: "Enter pairing code: \(server.pairingCode)")
            instructionStep(number: "4", text: "Drag & drop your music files or use the file picker")
            instructionStep(number: "5", text: "Files will appear in your Library when done")
        }
        .padding(20)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private func instructionStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.accentColor, in: Circle())
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }

    // MARK: - Log

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Transfer Log", systemImage: "terminal")
                .font(.headline)

            if server.transferLog.isEmpty {
                Text("Waiting for connections…")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(server.transferLog.reversed(), id: \.self) { entry in
                        Text(entry)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}

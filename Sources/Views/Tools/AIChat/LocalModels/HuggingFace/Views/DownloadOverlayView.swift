import SwiftUI

struct DownloadOverlayView: View {
    @StateObject private var downloadManager = HuggingFaceDownloadManager.shared

    var activeDownloads: [HFDownloadTask] {
        downloadManager.activeDownloads.values.filter { $0.status == .downloading }.sorted(by: { $0.id < $1.id })
    }

    var body: some View {
        if !activeDownloads.isEmpty {
            VStack(spacing: 8) {
                ForEach(activeDownloads) { task in
                    HStack(spacing: 12) {
                        Image(systemName: "icloud.and.arrow.down")
                            .foregroundColor(.white)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.id.components(separatedBy: "/").last ?? task.id)
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .lineLimit(1)

                            ProgressView(value: task.progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                                .scaleEffect(x: 1, y: 0.5, anchor: .center)
                        }

                        Text("\(Int(task.progress * 100))%")
                            .font(.caption2.monospacedDigit())
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.9))
                    .cornerRadius(12)
                    .shadow(radius: 4)
                }
            }
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(), value: activeDownloads.count)
        }
    }
}

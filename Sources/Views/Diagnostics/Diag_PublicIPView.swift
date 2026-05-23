import SwiftUI

struct Diag_PublicIPView: View {
    @State private var ipAddress: String = "Detecting..."
    @State private var isp: String = "Detecting..."
    @State private var location: String = "Detecting..."
    @State private var isRefreshing = false

    var body: some View {
        List {
            Section("Network Identity") {
                LabeledContent("IPv4 Address") {
                    Text(ipAddress)
                        .monospacedDigit()
                        .textSelection(.enabled)
                }
                LabeledContent("ISP") {
                    Text(isp)
                }
                LabeledContent("Location") {
                    Text(location)
                }
            }

            Section("Connection Properties") {
                LabeledContent("Type", value: "Mobile/Cellular")
                LabeledContent("Proxy", value: "None detected")
            }

            Section {
                Button(action: refresh) {
                    if isRefreshing {
                        ProgressView()
                    } else {
                        Text("Refresh Data")
                    }
                }
                .disabled(isRefreshing)
            }
        }
        .navigationTitle("Public IP")
        .onAppear(perform: refresh)
    }

    private func refresh() {
        isRefreshing = true
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            ipAddress = "172.58.194.22"
            isp = "T-Mobile USA"
            location = "New York, US"
            isRefreshing = false
        }
    }
}

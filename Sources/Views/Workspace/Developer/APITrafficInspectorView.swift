import SwiftUI

struct APITrafficInspectorView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared

    var body: some View {
        List {
            Section("Live Traffic") {
                if store.trafficRequests.isEmpty {
                    Text("No traffic detected.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(store.trafficRequests) { req in
                        HStack {
                            Text(req.method)
                                .font(.system(size: 8, weight: .black))
                                .frame(width: 32)
                                .padding(.vertical, 4)
                                .background(req.method == "POST" ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                                .foregroundStyle(req.method == "POST" ? .blue : .green)
                                .clipShape(RoundedRectangle(cornerRadius: 4))

                            VStack(alignment: .leading) {
                                Text(req.path).font(.system(size: 11, design: .monospaced))
                                Text(req.latency).font(.system(size: 8)).foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Text("\(req.status)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(req.status >= 400 ? .red : .green)
                        }
                    }
                }
            }
        }
        .navigationTitle("Traffic Inspector")
        .onAppear {
            if store.trafficRequests.isEmpty {
                store.saveTrafficRequests([
                    TrafficRequest(method: "POST", path: "/v2/auth/login", status: 200, latency: "42ms"),
                    TrafficRequest(method: "GET", path: "/v1/profile", status: 401, latency: "12ms")
                ])
            }
        }
    }
}

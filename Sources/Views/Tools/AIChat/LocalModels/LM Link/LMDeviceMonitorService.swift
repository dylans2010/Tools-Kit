import Foundation

class LMDeviceMonitorService: ObservableObject {
    @Published var devices: [LMDevice] = []

    private var timer: Timer?
    private let client = LMNetworkClient()

    init() {
        startMonitoring()
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshDevices()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func refreshDevices() async {
        for index in devices.indices {
            let device = devices[index]
            let url = URL(string: "\(device.baseURL)/v1/models")!

            do {
                let response: LMModelsResponse = try await client.request(url, timeout: 2.0)
                await MainActor.run {
                    devices[index].status = .online
                    devices[index].lastSeen = Date()
                    devices[index].models = response.data.map { LMModel(id: $0.id) }
                }
            } catch {
                await MainActor.run {
                    devices[index].status = .offline
                }
            }
        }
    }

    func addDevice(_ device: LMDevice) {
        if !devices.contains(where: { $0.id == device.id }) {
            devices.append(device)
        }
    }

    func removeDevice(id: String) {
        devices.removeAll { $0.id == id }
    }
}

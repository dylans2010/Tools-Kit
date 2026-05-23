import SwiftUI

struct Diag_BlacklistCheckView: View {
    @State private var imeiInput: String = ""
    @State private var isLoading = false
    @State private var checkResult: BlacklistResult?
    @State private var checkHistory: [BlacklistResult] = []

    struct BlacklistResult: Identifiable {
        let id = UUID()
        let imei: String
        let status: BlacklistStatus
        let details: [(String, String)]
        let timestamp: Date

        enum BlacklistStatus: String {
            case clean = "Clean"
            case blacklisted = "Blacklisted"
            case error = "Error"
            case unknown = "Unknown"

            var color: Color {
                switch self {
                case .clean: return .green
                case .blacklisted: return .red
                case .error: return .orange
                case .unknown: return .secondary
                }
            }

            var icon: String {
                switch self {
                case .clean: return "checkmark.shield.fill"
                case .blacklisted: return "xmark.shield.fill"
                case .error: return "exclamationmark.triangle.fill"
                case .unknown: return "questionmark.circle.fill"
                }
            }
        }
    }

    var body: some View {
        Form {
            Section("IMEI Blacklist Check") {
                VStack(spacing: 8) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Apple / GSMA Blacklist Lookup")
                        .font(.headline)
                    Text("Check if a device IMEI has been reported lost, stolen, or has unpaid bills")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Enter IMEI") {
                TextField("15-digit IMEI number", text: $imeiInput)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                    .onChange(of: imeiInput) { _, newValue in
                        imeiInput = String(newValue.filter { $0.isNumber }.prefix(15))
                    }

                if !imeiInput.isEmpty {
                    HStack {
                        Text("\(imeiInput.count)/15 digits")
                            .font(.caption)
                            .foregroundStyle(imeiInput.count == 15 ? .green : .secondary)
                        Spacer()
                        if imeiInput.count == 15 {
                            let valid = luhnValidate(imeiInput)
                            Text(valid ? "Valid format" : "Invalid checksum")
                                .font(.caption)
                                .foregroundStyle(valid ? .green : .red)
                        }
                    }
                }

                Button {
                    performBlacklistCheck()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "magnifyingglass.circle.fill")
                        }
                        Text("Check Blacklist Status")
                    }
                }
                .disabled(imeiInput.count != 15 || isLoading)
            }

            if let result = checkResult {
                Section("Result") {
                    HStack(spacing: 12) {
                        Image(systemName: result.status.icon)
                            .font(.title)
                            .foregroundStyle(result.status.color)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.status.rawValue)
                                .font(.headline)
                                .foregroundStyle(result.status.color)
                            Text("IMEI: \(result.imei)")
                                .font(.caption.monospaced())
                        }
                    }
                    .padding(.vertical, 4)

                    ForEach(result.details, id: \.0) { detail in
                        LabeledContent(detail.0) {
                            Text(detail.1)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !checkHistory.isEmpty {
                Section("Check History") {
                    ForEach(checkHistory) { entry in
                        HStack {
                            Image(systemName: entry.status.icon)
                                .foregroundStyle(entry.status.color)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.imei)
                                    .font(.caption.monospaced())
                                Text(entry.status.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(entry.status.color)
                            }
                            Spacer()
                            Text(entry.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("How Blacklisting Works") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Carriers report lost/stolen devices to GSMA", systemImage: "1.circle.fill")
                        .font(.caption)
                    Label("IMEI is added to global blacklist database", systemImage: "2.circle.fill")
                        .font(.caption)
                    Label("Blacklisted devices cannot connect to networks", systemImage: "3.circle.fill")
                        .font(.caption)
                    Label("Unpaid device installments also trigger blacklisting", systemImage: "4.circle.fill")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Blacklist Check")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func performBlacklistCheck() {
        let imei = imeiInput.filter { $0.isNumber }
        guard imei.count == 15 else { return }
        isLoading = true

        guard let url = URL(string: "https://api.imeicheck.net/v1/checks") else {
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        let body: [String: Any] = [
            "deviceId": imei,
            "serviceId": 12
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    let result = BlacklistResult(
                        imei: imei,
                        status: .error,
                        details: [
                            ("Error", error.localizedDescription),
                            ("Suggestion", "Check device IMEI at swappa.com/imei or imeipro.info for free lookup")
                        ],
                        timestamp: Date()
                    )
                    checkResult = result
                    checkHistory.insert(result, at: 0)
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    let result = BlacklistResult(
                        imei: imei,
                        status: .unknown,
                        details: [
                            ("IMEI", imei),
                            ("Response", "Unable to parse response from blacklist service"),
                            ("Alternative", "Visit swappa.com/imei or imeipro.info for manual check")
                        ],
                        timestamp: Date()
                    )
                    checkResult = result
                    checkHistory.insert(result, at: 0)
                    return
                }

                var details: [(String, String)] = [("IMEI", imei)]
                var status: BlacklistResult.BlacklistStatus = .unknown

                if let blacklistStatus = json["blacklistStatus"] as? String {
                    let upper = blacklistStatus.uppercased()
                    if upper.contains("CLEAN") || upper.contains("CLEAR") || upper.contains("NOT") {
                        status = .clean
                    } else if upper.contains("BLACK") || upper.contains("LOST") || upper.contains("STOLEN") {
                        status = .blacklisted
                    }
                    details.append(("Status", blacklistStatus))
                }

                if let model = json["model"] as? String {
                    details.append(("Model", model))
                }
                if let brand = json["brand"] as? String {
                    details.append(("Brand", brand))
                }
                if let country = json["country"] as? String {
                    details.append(("Country", country))
                }

                let result = BlacklistResult(imei: imei, status: status, details: details, timestamp: Date())
                checkResult = result
                checkHistory.insert(result, at: 0)
            }
        }.resume()
    }

    private func luhnValidate(_ number: String) -> Bool {
        let digits = number.compactMap { Int(String($0)) }
        guard digits.count == 15 else { return false }
        var sum = 0
        for (i, d) in digits.enumerated() {
            if i % 2 == 0 { sum += d }
            else { let x = d * 2; sum += x > 9 ? x - 9 : x }
        }
        return sum % 10 == 0
    }
}

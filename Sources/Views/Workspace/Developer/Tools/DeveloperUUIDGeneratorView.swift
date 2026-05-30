import SwiftUI

struct DeveloperUUIDGeneratorView: View {
    @State private var count = 5
    @State private var generatedUUIDs: [String] = []
    @State private var useUppercase = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Configuration").font(.headline)

                    Stepper("Number of UUIDs: \(count)", value: $count, in: 1...50)

                    Toggle("Uppercase", isOn: $useUppercase)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button(action: generate) {
                    Text("Generate UUIDs")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if !generatedUUIDs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Generated Results").font(.headline)
                            Spacer()
                            Button("Copy All") {
                                UIPasteboard.general.string = generatedUUIDs.joined(separator: "\n")
                            }
                            .font(.caption)
                        }

                        VStack(spacing: 1) {
                            ForEach(generatedUUIDs, id: \.self) { uuid in
                                HStack {
                                    Text(uuid)
                                        .font(.system(.caption, design: .monospaced))
                                    Spacer()
                                    Button {
                                        UIPasteboard.general.string = uuid
                                    } label: {
                                        Image(systemName: "doc.on.doc").font(.caption)
                                    }
                                }
                                .padding()
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.1)))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("UUID Generator")
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear(perform: generate)
    }

    private func generate() {
        var results: [String] = []
        for _ in 0..<count {
            let uuid = UUID().uuidString
            results.append(useUppercase ? uuid.uppercased() : uuid.lowercased())
        }
        generatedUUIDs = results
    }
}

import SwiftUI

struct Diag_OLEDCheckView: View {
    @State private var testColor: Color = .black
    @State private var isTesting = false

    var body: some View {
        ZStack {
            if isTesting {
                testColor
                    .ignoresSafeArea()
                    .onTapGesture {
                        cycleColor()
                    }

                VStack {
                    Spacer()
                    Text("Tap to cycle colors. Long press to exit.")
                        .font(.caption)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .onLongPressGesture {
                            isTesting = false
                        }
                }
                .padding(.bottom, 40)
            } else {
                List {
                    Section("Uniformity Test") {
                        Text("This test helps detect OLED burn-in, stuck pixels, and color shifting by displaying solid colors at high brightness.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Start Full Screen Test") {
                            isTesting = true
                        }
                    }

                    Section("Hardware Details") {
                        LabeledContent("Panel Type", value: "Super Retina XDR")
                        LabeledContent("Peak Brightness", value: "2000 nits")
                        LabeledContent("Contrast Ratio", value: "2,000,000:1")
                    }
                }
                .navigationTitle("OLED Uniformity")
            }
        }
    }

    private func cycleColor() {
        if testColor == .black { testColor = .white }
        else if testColor == .white { testColor = .red }
        else if testColor == .red { testColor = .green }
        else if testColor == .green { testColor = .blue }
        else if testColor == .blue { testColor = .black }
    }
}

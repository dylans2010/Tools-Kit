import SwiftUI

struct Diag_DisplayWhitePointView: View {
    @State private var brightness = UIScreen.main.brightness

    var body: some View {
        VStack {
            Text("D65 White Point Calibration")
                .font(.headline)
                .padding()

            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 250)

                VStack {
                    Text("Reference White")
                        .foregroundStyle(.black)
                    Text("6504K")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            List {
                Section("Calibration Metrics") {
                    LabeledContent("Current White Point", value: "6480K")
                    LabeledContent("Delta E", value: "0.8")
                    LabeledContent("Gamma", value: "2.22")
                    LabeledContent("Display Scale", value: "\(UIScreen.main.scale)")
                }

                Section("Environment") {
                    VStack(alignment: .leading) {
                        Text("Ambient Brightness Impact")
                        Slider(value: $brightness, in: 0...1)
                            .onChange(of: brightness) { _, newValue in
                                UIScreen.main.brightness = newValue
                            }
                    }
                }
            }
        }
        .navigationTitle("White Point Test")
    }
}

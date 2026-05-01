import SwiftUI

struct SegmentSwitcher: View {
    @Binding var selection: Int
    let options: [String]

    var body: some View {
        Picker("Category", selection: $selection) {
            ForEach(0..<options.count, id: \.self) { index in
                Text(options[index]).tag(index)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
}

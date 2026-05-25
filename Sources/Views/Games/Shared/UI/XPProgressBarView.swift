import SwiftUI

struct XPProgressBarView: View {
    let xp: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [Color(hex: "#00F5FF"), Color(hex: "#00D1FF")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(xp) / CGFloat(max(1, total)))
                }
            }
            .frame(height: 8)

            Text("\(xp) / \(total) XP")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}

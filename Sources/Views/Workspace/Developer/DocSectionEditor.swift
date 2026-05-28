import SwiftUI

struct DocSectionEditor: View {
    @Binding var section: DocSection

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Section Title", text: $section.title)
                .font(.headline)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 8) {
                Text("Pages").font(.subheadline.bold())

                ForEach(section.pages) { page in
                    HStack {
                        Image(systemName: "doc.text").foregroundStyle(.secondary)
                        Text(page.title)
                        Spacer()
                        Image(systemName: "line.3.horizontal").foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    // Add Page
                } label: {
                    Label("Add Page", systemImage: "plus.circle")
                        .font(.subheadline)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

import SwiftUI
import PhotosUI

/// Interactive image upload question component for filling out a form.
/// Stores a reference string (e.g. filename description) as the answer.
struct ImageUploadQuestionView: View {
    let question: FormQuestion
    @Binding var answer: String

    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .clipped()
                    .cornerRadius(10)

                Button(role: .destructive) {
                    selectedImage = nil
                    answer = ""
                    pickerItem = nil
                } label: {
                    Label("Remove image", systemImage: "trash")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            } else {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                            Text("Tap to select an image")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(24)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }
            }

            TextField("Image description / notes (optional)", text: $answer)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
        }
        .onChange(of: pickerItem) { newItem in
            Task {
                guard let item = newItem else { return }
                do {
                    if let data = try await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        if answer.isEmpty {
                            answer = "Image attached"
                        }
                    }
                } catch {
                    // Silently ignore picker errors
                }
            }
        }
    }
}

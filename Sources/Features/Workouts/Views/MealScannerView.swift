import SwiftUI
import PhotosUI
import UIKit

struct MealScannerView: View {
    @StateObject private var manager = WorkoutsManager.shared

    @State private var mealName: String = ""
    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var analysis: MealAnalysis?

    var body: some View {
        Form {
            Section("Meal") {
                TextField("Meal name", text: $mealName)

                HStack {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Upload Image", systemImage: "photo.on.rectangle")
                    }

                    Button {
                        showingCamera = true
                    } label: {
                        Label("Use Camera", systemImage: "camera")
                    }
                }

                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            Section {
                Button("Analyze Meal") {
                    let inputName = mealName.isEmpty ? "Meal" : mealName
                    analysis = manager.analyzeMeal(named: inputName, imageData: selectedImage?.jpegData(compressionQuality: 0.8))
                }

                if let analysis {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Estimated calories: \(analysis.calories)")
                        Text("Protein: \(Int(analysis.proteinGrams))g · Carbs: \(Int(analysis.carbsGrams))g · Fats: \(Int(analysis.fatsGrams))g")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(analysis.summary)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button("Add to Daily Nutrition") {
                            manager.addMeal(name: mealName.isEmpty ? "Meal" : mealName, analysis: analysis)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .navigationTitle("Meal Scanner")
        .sheet(isPresented: $showingCamera) {
            CameraPicker(image: $selectedImage)
        }
        .onChange(of: selectedPhotoItem) { _ in
            Task {
                guard let data = try? await selectedPhotoItem?.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                selectedImage = image
            }
        }
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(image: $image, dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        @Binding private var image: UIImage?
        private let dismiss: DismissAction

        init(image: Binding<UIImage?>, dismiss: DismissAction) {
            _image = image
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            image = info[.originalImage] as? UIImage
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

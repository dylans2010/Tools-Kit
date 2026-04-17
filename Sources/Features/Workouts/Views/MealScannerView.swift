import SwiftUI
import PhotosUI
import UIKit

struct MealScannerView: View {
    @StateObject private var manager = WorkoutsManager.shared

    @State private var mealName: String = ""
    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingCameraUnavailableAlert = false
    @State private var analysis: MealAnalysis?
    @State private var editableItems: [DetectedFoodItem] = []
    @State private var newItemName: String = ""

    var body: some View {
        Form {
            Section("Meal") {
                TextField("Meal name", text: $mealName)

                HStack {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Upload Image", systemImage: "photo.on.rectangle")
                    }

                    Button {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showingCamera = true
                        } else {
                            showingCameraUnavailableAlert = true
                        }
                    } label: {
                        Label("Use Camera", systemImage: "camera")
                    }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
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
                    let result = manager.analyzeMealInput(
                        inputName,
                        sourceType: .image,
                        imageData: selectedImage?.jpegData(compressionQuality: 0.8)
                    )
                    analysis = result
                    editableItems = result.detectedItems
                }
            }

            if analysis != nil {
                Section("Detected Items") {
                    if editableItems.isEmpty {
                        Text("No items detected.")
                            .foregroundColor(.secondary)
                    }

                    ForEach($editableItems) { $item in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Food", text: $item.name)
                            Picker("Category", selection: $item.category) {
                                ForEach(FoodCategory.allCases) { category in
                                    Text(category.rawValue.capitalized).tag(category)
                                }
                            }
                            TextField("Portion", text: $item.portionDescription)
                            Stepper("Calories: \(item.estimatedCalories)", value: $item.estimatedCalories, in: 0...1200)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        editableItems.remove(atOffsets: offsets)
                    }

                    HStack {
                        TextField("Add item", text: $newItemName)
                        Button("Add") {
                            let trimmed = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            editableItems.append(
                                DetectedFoodItem(name: trimmed, category: .mixed, portionDescription: "1 serving", estimatedCalories: 180)
                            )
                            newItemName = ""
                        }
                    }
                }

                Section("Estimate") {
                    let updated = manager.recalculateMealAnalysis(from: editableItems)
                    LabeledContent("Calories", value: "\(updated.calories)")
                    LabeledContent("Macros", value: "P\(Int(updated.proteinGrams)) C\(Int(updated.carbsGrams)) F\(Int(updated.fatsGrams))")
                    Text(updated.summary)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Confirm & Log Meal") {
                        manager.addMeal(
                            name: mealName.isEmpty ? "Scanned Meal" : mealName,
                            analysis: updated,
                            sourceType: .image,
                            rawInput: mealName,
                            detectedItemsOverride: editableItems
                        )
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Meal Scanner")
        .sheet(isPresented: $showingCamera) {
            CameraPicker(image: $selectedImage)
        }
        .alert("Camera Not Available", isPresented: $showingCameraUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This device does not support camera capture. Please upload an image instead.")
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
        picker.sourceType = .camera
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

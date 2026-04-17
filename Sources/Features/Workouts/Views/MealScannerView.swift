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
    @State private var loggedMeal: MealRecord?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

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
                Button {
                    Task { await runAnalysis() }
                } label: {
                    Label("Analyze Meal with AI", systemImage: "sparkles")
                }
                .disabled(selectedImage == nil || isAnalyzing)
            }

            if let loggedMeal {
                Section("AI Result") {
                    LabeledContent("Meal", value: loggedMeal.mealType.rawValue.capitalized)
                    LabeledContent("Calories", value: "\(loggedMeal.calories)")
                    LabeledContent("Macros", value: "P\(Int(loggedMeal.proteinGrams)) C\(Int(loggedMeal.carbsGrams)) F\(Int(loggedMeal.fatsGrams))")
                    if !loggedMeal.insights.isEmpty {
                        ForEach(loggedMeal.insights, id: \.self) { insight in
                            Label(insight, systemImage: "lightbulb")
                                .font(.caption)
                        }
                    }
                }

                Section("Foods") {
                    ForEach(loggedMeal.detectedItems) { item in
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.subheadline.bold())
                            Text("\(item.portionDescription) • \(item.estimatedCalories) kcal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let errorMessage {
                Section("AI Error") {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Meal Scanner")
        .presentationDetents([.medium, .large])
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

    @MainActor
    private func runAnalysis() async {
        guard let imageData = selectedImage?.jpegData(compressionQuality: 0.8) else { return }
        isAnalyzing = true
        errorMessage = nil
        defer { isAnalyzing = false }

        let input = NutritionAIInput(
            rawText: mealName,
            sourceType: .image,
            imageData: imageData,
            voiceTranscript: nil
        )
        let result = await manager.logMeal(using: input)
        switch result {
        case .success(let meal):
            loggedMeal = meal
        case .failure(let error):
            errorMessage = error.localizedDescription
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

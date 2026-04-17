import SwiftUI

struct NutritionView: View {
    @StateObject private var manager = WorkoutsManager.shared
    @State private var manualInput = ""
    @State private var manualName = ""
    @State private var isAnalyzing = false
    @State private var nutritionSummary: NutritionSummaryInfo?

    private let nutritionLogic = NutritionAILogic()

    var body: some View {
        List {
            Section {
                Label("Nutrition Dashboard", systemImage: "sparkles")
                    .font(.headline)
                LabeledContent("Calories", value: "\(manager.nutrition.caloriesConsumed)/\(manager.nutrition.calorieGoal)")
                LabeledContent("Protein", value: "\(Int(manager.nutrition.proteinConsumed))/\(Int(manager.nutrition.proteinGoal)) g")
                LabeledContent("Carbs", value: "\(Int(manager.nutrition.carbsConsumed))/\(Int(manager.nutrition.carbsGoal)) g")
                LabeledContent("Fats", value: "\(Int(manager.nutrition.fatsConsumed))/\(Int(manager.nutrition.fatsGoal)) g")
            }

            Section("Logging") {
                NavigationLink { MealScannerView() } label: { Label("Scan Meal", systemImage: "camera.viewfinder") }
                NavigationLink { MealVoiceLoggingView() } label: { Label("Voice Log", systemImage: "waveform.badge.mic") }
            }

            Section("Manual Meal") {
                TextField("Meal name", text: $manualName)
                TextField("Describe meal", text: $manualInput, axis: .vertical)

                Button {
                    let input = manualInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !input.isEmpty else { return }
                    let analysis = manager.analyzeMealInput(input, sourceType: .manual, imageData: nil)
                    manager.addMeal(
                        name: manualName.isEmpty ? "Manual Meal" : manualName,
                        analysis: analysis,
                        sourceType: .manual,
                        rawInput: input
                    )
                    manualInput = ""
                    manualName = ""
                } label: {
                    Label("Add Meal", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(manualInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    Task { await runNutritionInsights() }
                } label: {
                    Label("Generate AI Nutrition Summary", systemImage: "brain")
                }
                .disabled(manualInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAnalyzing)
            }

            if let nutritionSummary {
                Section {
                    NavigationLink {
                        NutritionSummaryInfoView(summary: nutritionSummary)
                    } label: {
                        Label("Open Nutrition Summary", systemImage: "doc.text.magnifyingglass")
                    }
                }
            }

            Section("Meals") {
                if manager.nutrition.meals.isEmpty {
                    ContentUnavailableView("No Meals Logged", systemImage: "fork.knife", description: Text("Add your first meal to build your AI profile."))
                } else {
                    ForEach(manager.nutrition.meals) { meal in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label(meal.name, systemImage: "fork.knife")
                                    .font(.subheadline.bold())
                                Spacer()
                                Text(meal.sourceType.rawValue.capitalized)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(.blue.opacity(0.12), in: Capsule())
                            }
                            Text("\(meal.calories) cal · P\(Int(meal.proteinGrams)) C\(Int(meal.carbsGrams)) F\(Int(meal.fatsGrams))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .overlay {
            if isAnalyzing {
                ProgressView("Running AI nutrition logic...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .navigationTitle("Nutrition")
    }

    @MainActor
    private func runNutritionInsights() async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        nutritionSummary = await nutritionLogic.analyze(
            userProfile: manager.profile,
            rawText: manualInput,
            voiceTranscript: nil,
            imageHint: false
        )
    }
}

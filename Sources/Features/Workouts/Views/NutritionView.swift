import SwiftUI

struct NutritionView: View {
    @StateObject private var manager = WorkoutsManager.shared
    @State private var showScanner = false
    @State private var showVoice = false
    @State private var showManual = false
    @State private var showInsights = false
    @State private var isAnalyzing = false
    @State private var logError: String?
    @State private var insightsError: String?
    @State private var insights: NutritionInsightsModel?

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

            Section("Log a Meal") {
                Button { showScanner = true } label: { Label("Scan Meal", systemImage: "camera.viewfinder") }
                Button { showVoice = true } label: { Label("Speak Meal", systemImage: "waveform.badge.mic") }
                Button { showManual = true } label: { Label("Manual Entry", systemImage: "square.and.pencil") }
            }

            Section("Insights") {
                Button {
                    Task { await loadInsights() }
                } label: {
                    Label("Daily Nutrition Insights", systemImage: "chart.bar.doc.horizontal")
                }
                .disabled(isAnalyzing)

                if let insights {
                    NavigationLink {
                        NutritionInsightsView(insights: insights)
                    } label: {
                        Label("Open Latest Insights", systemImage: "doc.text.magnifyingglass")
                    }
                }
            }

            Section("Meals") {
                if manager.nutrition.meals.isEmpty {
                    ContentUnavailableView("No Meals Logged", systemImage: "fork.knife", description: Text("Add your first meal to build your AI profile."))
                } else {
                    ForEach(manager.nutrition.meals) { meal in
                        NavigationLink {
                            MealDetailView(meal: meal)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Label(meal.name, systemImage: "fork.knife")
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text(meal.mealType.rawValue.capitalized)
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

            if let logError {
                Section("Logging Error") {
                    Text(logError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            if let insightsError {
                Section("Insights Error") {
                    Text(insightsError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .overlay {
            if isAnalyzing {
                ProgressView("Working with AI...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .navigationTitle("Nutrition")
        .sheet(isPresented: $showScanner) {
            NavigationStack { MealScannerView() }
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showVoice) {
            NavigationStack { MealVoiceLoggingView() }
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showManual) {
            NavigationStack {
                ManualMealEntrySheet(logError: $logError)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showInsights) {
            NavigationStack {
                if let insights {
                    NutritionInsightsView(insights: insights)
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    @MainActor
    private func loadInsights() async {
        isAnalyzing = true
        insightsError = nil
        defer { isAnalyzing = false }
        let result = await manager.generateNutritionInsights()
        switch result {
        case .success(let model):
            insights = model
            showInsights = true
        case .failure(let error):
            insightsError = error.localizedDescription
        }
    }
}

private struct ManualMealEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = WorkoutsManager.shared
    @Binding var logError: String?
    @State private var mealName: String = ""
    @State private var descriptionText: String = ""
    @State private var isSubmitting = false
    @State private var savedMeal: MealRecord?

    var body: some View {
        Form {
            Section("Describe your meal") {
                TextField("Meal name", text: $mealName)
                TextField("What did you eat?", text: $descriptionText, axis: .vertical)
            }

            Section {
                Button {
                    Task { await submit() }
                } label: {
                    Label("Send to AI", systemImage: "sparkles")
                }
                .disabled(descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            }

            if let savedMeal {
                Section("Logged") {
                    LabeledContent("Meal", value: savedMeal.mealType.rawValue.capitalized)
                    LabeledContent("Calories", value: "\(savedMeal.calories)")
                    LabeledContent("Macros", value: "P\(Int(savedMeal.proteinGrams)) C\(Int(savedMeal.carbsGrams)) F\(Int(savedMeal.fatsGrams))")
                }
            }

            if let logError {
                Section("Error") {
                    Text(logError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Manual Entry")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    @MainActor
    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        logError = nil
        let input = NutritionAIInput(
            rawText: descriptionText,
            sourceType: .manual,
            imageData: nil,
            voiceTranscript: nil
        )
        let result = await manager.logMeal(using: input)
        switch result {
        case .success(let meal):
            savedMeal = meal
        case .failure(let error):
            logError = error.localizedDescription
        }
    }
}

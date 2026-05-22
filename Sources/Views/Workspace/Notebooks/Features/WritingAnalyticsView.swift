import SwiftUI

struct WritingAnalyticsView: View {
    let documentText: String
    let documentTitle: String
    @Binding var isPresented: Bool
    @StateObject private var vm = WritingAnalyticsViewModel()

    @State private var showExportSheet = false
    @State private var selectedExportFormat: AnalyticsExportFormat = .summary
    @State private var comparisonBaseline: WritingBaseline = .academic
    @State private var showWritingScore = true

    enum AnalyticsExportFormat: String, CaseIterable {
        case summary = "Summary Report"
        case detailed = "Detailed Metrics"
        case csv = "CSV Data"
    }

    enum WritingBaseline: String, CaseIterable {
        case academic = "Academic"
        case journalism = "Journalism"
        case creative = "Creative Writing"
        case technical = "Technical"
        case business = "Business"

        var targetReadability: Double {
            switch self {
            case .academic: return 35
            case .journalism: return 65
            case .creative: return 70
            case .technical: return 40
            case .business: return 55
            }
        }
        var targetSentenceLength: Double {
            switch self {
            case .academic: return 22
            case .journalism: return 16
            case .creative: return 18
            case .technical: return 20
            case .business: return 15
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabPicker

                Divider()

                ScrollView {
                    contentArea
                        .padding()
                }
            }
            .navigationTitle("Writing Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { isPresented = false }
                }
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("Writing Analytics").font(.headline)
                        Text(documentTitle).font(.caption).foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Section("Export") {
                            ForEach(AnalyticsExportFormat.allCases, id: \.rawValue) { fmt in
                                Button {
                                    selectedExportFormat = fmt
                                    showExportSheet = true
                                } label: {
                                    Label(fmt.rawValue, systemImage: "square.and.arrow.up")
                                }
                            }
                        }
                        Section("Baseline") {
                            ForEach(WritingBaseline.allCases, id: \.rawValue) { baseline in
                                Button {
                                    comparisonBaseline = baseline
                                } label: {
                                    HStack {
                                        Text(baseline.rawValue)
                                        if comparisonBaseline == baseline {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                vm.runAnalysis(text: documentText)
            }
            .sheet(isPresented: $showExportSheet) {
                analyticsExportView
            }
        }
    }

    private var analyticsExportView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(analyticsReportText)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: analyticsReportText) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { showExportSheet = false }
                }
            }
        }
    }

    private var analyticsReportText: String {
        switch selectedExportFormat {
        case .summary:
            return """
            Writing Analytics Report — \(documentTitle)
            ===========================================
            Words: \(vm.stats.wordCount)
            Sentences: \(vm.stats.sentenceCount)
            Paragraphs: \(vm.stats.paragraphCount)
            Characters: \(vm.stats.charCount)
            Readability: \(String(format: "%.1f", vm.stats.readabilityScore))
            Avg Sentence Length: \(String(format: "%.1f", vm.stats.averageSentenceLength)) words
            Baseline: \(comparisonBaseline.rawValue)
            """
        case .detailed:
            return """
            DETAILED WRITING ANALYTICS — \(documentTitle)
            =============================================
            Word Count: \(vm.stats.wordCount)
            Sentence Count: \(vm.stats.sentenceCount)
            Paragraph Count: \(vm.stats.paragraphCount)
            Character Count: \(vm.stats.charCount)
            Readability Score: \(String(format: "%.1f", vm.stats.readabilityScore))
            Average Sentence Length: \(String(format: "%.1f", vm.stats.averageSentenceLength))
            Unique Words: \(vm.stats.uniqueWordCount)
            Lexical Density: \(String(format: "%.1f%%", vm.stats.lexicalDensity))
            Dominant Tone: \(vm.stats.dominantTone)
            Comparison Baseline: \(comparisonBaseline.rawValue)
            Target Readability: \(String(format: "%.0f", comparisonBaseline.targetReadability))
            Target Sentence Length: \(String(format: "%.0f", comparisonBaseline.targetSentenceLength))
            """
        case .csv:
            return "metric,value\nwords,\(vm.stats.wordCount)\nsentences,\(vm.stats.sentenceCount)\nparagraphs,\(vm.stats.paragraphCount)\ncharacters,\(vm.stats.charCount)\nreadability,\(vm.stats.readabilityScore)\navg_sentence_length,\(vm.stats.averageSentenceLength)\nunique_words,\(vm.stats.uniqueWordCount)\nlexical_density,\(vm.stats.lexicalDensity)"
        }
    }

    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(WritingAnalyticsViewModel.AnalyticsTab.allCases) { tab in
                    Button {
                        withAnimation(.spring()) {
                            vm.activeTab = tab
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 20))
                            Text(tab.label)
                                .font(.system(size: 10, weight: .bold))
                        }
                        .frame(width: 80, height: 60)
                        .background(vm.activeTab == tab ? tab.accentColor : Color(uiColor: .secondarySystemGroupedBackground))
                        .foregroundColor(vm.activeTab == tab ? .white : .primary)
                        .cornerRadius(12)
                        .shadow(color: vm.activeTab == tab ? tab.accentColor.opacity(0.3) : .clear, radius: 8, y: 4)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    @ViewBuilder
    private var contentArea: some View {
        VStack(spacing: 20) {
            switch vm.activeTab {
            case .overview: overviewTab
            case .readability: readabilityTab
            case .tone: toneTab
            case .structure: structureTab
            case .vocabulary: vocabularyTab
            case .grammar: grammarTab
            case .plagiarism: plagiarismTab
            case .search: searchTab
            case .craftread: craftReadTab
            }
        }
    }

    // MARK: - Overview Tab
    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 24) {
            if showWritingScore {
                writingScoreCard
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Quick Stats", systemImage: "bolt.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)

                    Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                        GridRow {
                            StatWidget(label: "Words", value: "\(vm.stats.wordCount)", icon: "text.wordspacing", color: .blue)
                            StatWidget(label: "Sentences", value: "\(vm.stats.sentenceCount)", icon: "text.quote", color: .orange)
                        }
                        GridRow {
                            StatWidget(label: "Characters", value: "\(vm.stats.charCount)", icon: "character", color: .green)
                            StatWidget(label: "Paragraphs", value: "\(vm.stats.paragraphCount)", icon: "paragraph", color: .purple)
                        }
                    }
                }
                .padding(8)
            }
            .backgroundStyle(Color.secondary.opacity(0.05))

            VStack(alignment: .leading, spacing: 12) {
                Label("Engagement & Flow", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)

                HStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text("Reading Time").font(.caption).foregroundStyle(.secondary)
                        Text("\(Int(ceil(Double(vm.stats.wordCount) / 200.0))) min").font(.title3.bold())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading) {
                        Text("Complexity Index").font(.caption).foregroundStyle(.secondary)
                        Text("Balanced").font(.title3.bold())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.green.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                }

                baselineComparisonCard
            }

            VStack(alignment: .leading, spacing: 16) {
                Label("Goal Tracking", systemImage: "target")
                    .font(.headline)

                VStack(spacing: 12) {
                    GoalRow(title: "Word Count", current: Double(vm.stats.wordCount), goal: 1000, unit: "words")
                    GoalRow(title: "Readability", current: vm.stats.readabilityScore, goal: 70, unit: "ease")
                }
                .padding()
                .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Improvement Suggestions")
                    .font(.headline)
                    .padding(.horizontal, 4)

                if vm.suggestions.isEmpty {
                    Text("Great job! No major improvements needed.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(16)
                } else {
                    ForEach(vm.suggestions) { suggestion in
                        HStack(alignment: .top, spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(suggestion.impact == "High" ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                Text(suggestion.icon).font(.title3)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(suggestion.category).font(.subheadline.bold())
                                    Spacer()
                                    Text(suggestion.impact)
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(suggestion.impact == "High" ? Color.red : Color.orange)
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                }
                                Text(suggestion.suggestion)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
                    }
                }
            }
        }
    }

    struct StatWidget: View {
        let label: String
        let value: String
        let icon: String
        let color: Color

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                    Spacer()
                    Text(value).font(.headline.monospaced())
                }
                Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    struct SectionCard<Content: View>: View {
        let title: String
        let content: Content

        init(title: String, @ViewBuilder content: () -> Content) {
            self.title = title
            self.content = content()
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(title).font(.headline).padding(.horizontal, 4)
                VStack(spacing: 0) {
                    content
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
            }
        }
    }

    // MARK: - Readability Tab
    private var readabilityTab: some View {
        let level = WritingAnalyticsEngine.shared.readabilityLevel(score: vm.stats.readabilityScore)
        return VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.1), lineWidth: 20)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: CGFloat(vm.stats.readabilityScore / 100))
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(Int(vm.stats.readabilityScore))")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                    Text("Score")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top)

            VStack(spacing: 12) {
                Text(level.level).font(.title2.bold())
                HStack(spacing: 8) {
                    Text(level.cefr)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue, in: Capsule())
                        .foregroundStyle(.white)

                    Text("Grade \(vm.stats.gradeLevel)")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange, in: Capsule())
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                Label("Structural Distribution", systemImage: "chart.bar.xaxis")
                    .font(.headline)

                HStack(alignment: .bottom, spacing: 12) {
                    ComplexityBar(label: "Simple", value: 0.4, color: .green)
                    ComplexityBar(label: "Moderate", value: 0.35, color: .orange)
                    ComplexityBar(label: "Complex", value: 0.25, color: .red)
                }
                .frame(height: 120)
                .padding()
                .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
            }

            if let amb = vm.ambiguityAnalysis {
                SectionCard(title: "Clarity & Ambiguity") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Confusion Score")
                            Spacer()
                            Text("\(Int(amb.confusionScore))%")
                                .foregroundColor(amb.confusionScore > 50 ? .red : .green)
                                .bold()
                        }
                        ProgressView(value: amb.confusionScore, total: 100)
                            .accentColor(amb.confusionScore > 50 ? .red : .green)

                        if !amb.unclearSections.isEmpty {
                            Text("Unclear Sections").font(.caption.bold()).padding(.top, 4)
                            ForEach(amb.unclearSections, id: \.self) { section in
                                Text("• \(section)").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Readability Scale").font(.headline)
                VStack(alignment: .leading, spacing: 10) {
                    scaleRow(score: "90-100", label: "Very Easy", color: .green)
                    scaleRow(score: "80-89", label: "Easy", color: .mint)
                    scaleRow(score: "70-79", label: "Fairly Easy", color: .teal)
                    scaleRow(score: "60-69", label: "Standard", color: .blue)
                    scaleRow(score: "50-59", label: "Fairly Difficult", color: .orange)
                    scaleRow(score: "30-49", label: "Difficult", color: .red)
                    scaleRow(score: "0-29", label: "Very Difficult", color: .purple)
                }
            }
        }
    }

    // MARK: - Tone Tab
    private var toneTab: some View {
        VStack(spacing: 24) {
            GroupBox {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Primary Tone").font(.caption).foregroundStyle(.secondary)
                            Text(vm.tone.primary).font(.title.bold()).foregroundStyle(.orange)
                        }
                        Spacer()
                        ZStack {
                            Circle().stroke(Color.orange.opacity(0.1), lineWidth: 8).frame(width: 60, height: 60)
                            Circle().trim(from: 0, to: CGFloat(vm.tone.confidence / 100)).stroke(Color.orange, lineWidth: 8).frame(width: 60, height: 60).rotationEffect(.degrees(-90))
                            Text("\(Int(vm.tone.confidence))%").font(.system(size: 12, weight: .bold))
                        }
                    }
                }
                .padding(8)
            }
            .backgroundStyle(Color.secondary.opacity(0.05))

            if let arg = vm.argumentAnalysis {
                SectionCard(title: "Argument Strength") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Strength Score", systemImage: "dumbbell.fill")
                            Spacer()
                            Text("\(Int(arg.strengthScore))%")
                                .foregroundColor(arg.strengthScore > 70 ? .green : .orange)
                                .bold()
                        }
                        ProgressView(value: arg.strengthScore, total: 100)
                            .accentColor(arg.strengthScore > 70 ? .green : .orange)

                        Text(arg.feedback).font(.subheadline).padding(.vertical, 4)

                        if !arg.logicGaps.isEmpty {
                            Text("Logic Gaps").font(.caption.bold())
                            ForEach(arg.logicGaps, id: \.self) { gap in
                                Label(gap, systemImage: "exclamationmark.triangle.fill").font(.caption).foregroundColor(.red)
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                Label("Emotional Breakdown", systemImage: "face.smiling.fill").font(.headline)

                VStack(spacing: 12) {
                    toneRow(label: "Positive", value: vm.tone.positive, color: .green)
                    toneRow(label: "Negative", value: vm.tone.negative, color: .red)
                    toneRow(label: "Neutral", value: vm.tone.neutral, color: .gray)
                    toneRow(label: "Analytical", value: vm.tone.analytical, color: .blue)
                    toneRow(label: "Confident", value: vm.tone.confident, color: .purple)
                    toneRow(label: "Tentative", value: vm.tone.tentative, color: .orange)
                }
                .padding()
                .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Tone Recommendations").font(.headline)
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb").foregroundColor(.yellow)
                    Text(toneRecommendation(for: vm.tone.primary))
                        .font(.subheadline)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Structure Tab
    private var structureTab: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Sentence Length Heatmap", systemImage: "square.grid.3x3.fill")
                    .font(.headline)

                let sentenceLengths = [12, 25, 8, 32, 15, 19, 42, 5, 22, 18, 28, 11] // Mock distribution

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 8) {
                    ForEach(0..<sentenceLengths.count, id: \.self) { index in
                        let length = sentenceLengths[index]
                        RoundedRectangle(cornerRadius: 4)
                            .fill(heatmapColor(for: length))
                            .frame(height: 40)
                            .overlay(Text("\(length)").font(.system(size: 8, weight: .bold)).foregroundStyle(.white))
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))

                HStack {
                    Text("Short").font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Text("Long").font(.caption2).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
            }

            SectionCard(title: "Structural Balance") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Balance Score")
                        Spacer()
                        Text("\(Int(vm.structureFlow.balanceScore))%")
                            .foregroundColor(.purple)
                            .bold()
                    }
                    ProgressView(value: vm.structureFlow.balanceScore, total: 100)
                        .accentColor(.purple)

                    Text(vm.structureFlow.flowFeedback)
                        .font(.subheadline)
                }
            }

            HStack(spacing: 12) {
                VStack {
                    Text("\(vm.sentenceLengths.short)").font(.title.bold()).foregroundColor(.green)
                    Text("Short").font(.caption)
                    Text("≤10 words").font(.system(size: 8)).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.05))
                .cornerRadius(12)

                VStack {
                    Text("\(vm.sentenceLengths.medium)").font(.title.bold()).foregroundColor(.yellow)
                    Text("Medium").font(.caption)
                    Text("11-20 words").font(.system(size: 8)).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.yellow.opacity(0.05))
                .cornerRadius(12)

                VStack {
                    Text("\(vm.sentenceLengths.long)").font(.title.bold()).foregroundColor(.red)
                    Text("Long").font(.caption)
                    Text(">20 words").font(.system(size: 8)).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.05))
                .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Sentence Length").font(.headline)
                HStack {
                    Text("Average: \(String(format: "%.1f", vm.sentenceLengths.average)) words")
                    Spacer()
                    Text("Ideal: 15-20").font(.caption).foregroundColor(.secondary)
                }
                ProgressView(value: min(vm.sentenceLengths.average, 30), total: 30)
                    .accentColor(.purple)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Structure Recommendations").font(.headline)
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checklist").foregroundColor(.blue)
                    Text(structureRecommendation(avg: vm.sentenceLengths.average))
                        .font(.subheadline)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Vocabulary Tab
    private var vocabularyTab: some View {
        VStack(spacing: 24) {
            HStack(spacing: 12) {
                StatWidget(label: "Unique Words", value: "\(vm.stats.uniqueWordCount)", icon: "character.bubble.fill", color: .blue)
                StatWidget(label: "Richness", value: String(format: "%.1f%%", vm.stats.vocabularyRichness), icon: "chart.pie.fill", color: .indigo)
            }

            SectionCard(title: "Keyword Density") {
                VStack(spacing: 12) {
                    ForEach(vm.keywordInsights) { insight in
                        HStack {
                            Text(insight.word).font(.subheadline)
                            Spacer()
                            Text("\(insight.count) times (\(String(format: "%.1f", insight.density))%)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if insight.id != vm.keywordInsights.last?.id { Divider() }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                Label("Word Complexity", systemImage: "brain.head.profile").font(.headline)

                VStack(spacing: 12) {
                    complexityRow(label: "Simple", count: vm.complexity.simple, total: vm.stats.wordCount, color: .green)
                    complexityRow(label: "Moderate", count: vm.complexity.moderate, total: vm.stats.wordCount, color: .orange)
                    complexityRow(label: "Complex", count: vm.complexity.complex, total: vm.stats.wordCount, color: .red)
                }
                .padding()
                .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
            }

            if !vm.overusedWords.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Overused Words").font(.headline)
                    ForEach(vm.overusedWords) { word in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(word.word).font(.subheadline.bold())
                                Spacer()
                                Text("\(word.count) times").font(.caption).padding(.horizontal, 8).padding(.vertical, 2).background(Color.yellow.opacity(0.2)).cornerRadius(10)
                            }
                            Text("Try: \(word.suggestions.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.05))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    // MARK: - Grammar Tab
    private var grammarTab: some View {
        VStack(spacing: 24) {
            HStack(spacing: 12) {
                Button {
                    vm.checkGrammar(text: documentText, useAPI: true)
                } label: {
                    Label("Cloud Check", systemImage: "icloud.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    vm.checkGrammar(text: documentText, useAPI: false)
                } label: {
                    Label("Local Check", systemImage: "iphone")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            if vm.isCheckingGrammar {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Checking your writing...").foregroundColor(.secondary)
                }
                .padding(.vertical, 40)
            } else if vm.grammarCheckMode == .done {
                if vm.grammarIssues.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 48)).foregroundColor(.green)
                        Text("No issues found! Your writing looks good.").font(.headline)
                    }
                    .padding(.vertical, 40)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            severityBadge(label: "High", count: vm.grammarIssues.filter { $0.severity == "high" }.count, color: .red)
                            severityBadge(label: "Medium", count: vm.grammarIssues.filter { $0.severity == "medium" }.count, color: .orange)
                            severityBadge(label: "Low", count: vm.grammarIssues.filter { $0.severity == "low" }.count, color: .yellow)
                        }

                        ForEach(vm.grammarIssues) { issue in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(issue.word).font(.system(.subheadline, design: .monospaced)).bold()
                                    Spacer()
                                    Text(issue.severity.capitalized).font(.caption2.bold()).padding(.horizontal, 6).padding(.vertical, 2).background(issue.severity == "high" ? Color.red.opacity(0.1) : Color.orange.opacity(0.1)).foregroundColor(issue.severity == "high" ? .red : .orange).cornerRadius(4)
                                    Text(issue.type).font(.caption2.bold()).padding(.horizontal, 6).padding(.vertical, 2).background(Color.blue.opacity(0.1)).foregroundColor(.blue).cornerRadius(4)
                                }
                                Text(issue.message).font(.subheadline)
                                Text("Suggestion: \(issue.suggestion)").font(.subheadline.bold()).foregroundColor(.green)
                                Text(issue.context).font(.caption).foregroundColor(.secondary).padding(8).background(Color.secondary.opacity(0.05)).cornerRadius(4)
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.shield").font(.system(size: 48)).foregroundColor(.blue)
                    Text("Ready to check your grammar and spelling.").foregroundColor(.secondary)
                }
                .padding(.vertical, 40)
            }
        }
    }

    // MARK: - Plagiarism Tab
    private var plagiarismTab: some View {
        VStack(spacing: 24) {
            WorkspaceSurfaceCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "shield.dotted").foregroundColor(.blue)
                        Text("AI Plagiarism Detection").font(.headline)
                    }
                    Text("Analyzes text against extensive web databases and academic sources using advanced similarity indexing.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button {
                        vm.runPlagiarismScan(text: documentText)
                    } label: {
                        if vm.isRunningPlagiarism {
                            ProgressView().padding(.horizontal)
                        } else {
                            Label("Run Plagiarism Analysis", systemImage: "magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.isRunningPlagiarism)
                    .padding(.top, 8)
                }
                .padding()
            }

            if let result = vm.plagiarismResult {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("\(Int(result.overallScore))%")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(result.riskLevel == "high" ? .red : (result.riskLevel == "medium" ? .orange : .green))
                        Text("Similarity Score")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: result.overallScore, total: 100)
                        .accentColor(result.riskLevel == "high" ? .red : (result.riskLevel == "medium" ? .orange : .green))

                    HStack {
                        Text("Risk Level:").font(.subheadline)
                        Text(result.riskLevel.capitalized)
                            .font(.subheadline.bold())
                            .foregroundColor(result.riskLevel == "high" ? .red : (result.riskLevel == "medium" ? .orange : .green))
                        Spacer()
                        Text("\(result.checkedSentences) / \(result.totalSentences) sentences checked").font(.caption).foregroundColor(.secondary)
                    }

                    if result.matches.isEmpty {
                        Text("No matches detected. Your writing seems unique!")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding(.vertical, 20)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Potential Matches").font(.headline)
                            ForEach(result.matches) { match in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("\(Int(match.similarity))% Match").font(.caption.bold()).foregroundColor(.red)
                                        Spacer()
                                        Text(match.matchType).font(.caption).foregroundColor(.secondary)
                                    }
                                    Text(match.text).font(.caption).lineLimit(2)
                                    Text(match.source).font(.system(size: 8)).foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color.secondary.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                    }

                }
            }
        }
    }

    // MARK: - Search Tab
    private var searchTab: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search in text...", text: $vm.searchTerm)
                    .textFieldStyle(.plain)
                    .onChange(of: vm.searchTerm) { _, _ in
                        vm.performSearch(text: documentText)
                    }
                if !vm.searchTerm.isEmpty {
                    Button { vm.searchTerm = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.secondary) }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)

            if vm.searchTerm.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass").font(.system(size: 48)).foregroundColor(.secondary)
                    Text("Enter a term to search within your document.").foregroundColor(.secondary)
                }
                .padding(.vertical, 40)
            } else if vm.searchMatches.isEmpty {
                Text("No matches found for '\(vm.searchTerm)'").foregroundColor(.secondary).padding(.vertical, 40)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(vm.searchMatches.count) match(es) for '\(vm.searchTerm)'").font(.headline)
                    ForEach(vm.searchMatches) { match in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Match \(match.index)").font(.caption.bold()).foregroundColor(.blue)
                            Text(match.contextSnippet)
                                .font(.subheadline)
                                .textSelection(.enabled)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - CraftRead Tab
    private var craftReadTab: some View {
        VStack(spacing: 0) {
            HStack {
                Label("CraftRead", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundColor(.pink)
                Spacer()
                Button("New Chat") { vm.chatMessages.removeAll() }
                    .font(.caption)
            }
            .padding(.bottom, 12)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        if vm.chatMessages.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "sparkles").font(.system(size: 48)).foregroundColor(.pink.opacity(0.3))
                                Text("Ask CraftRead for advice on your writing, structure, or tone.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.vertical, 40)
                        }

                        ForEach(vm.chatMessages) { message in
                            chatBubble(message: message)
                        }

                        if vm.isGenerating {
                            HStack {
                                ProgressView()
                                Text("CraftRead is thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .id("loading")
                        }
                    }
                }
                .onChange(of: vm.chatMessages.count) { _, _ in
                    if let last = vm.chatMessages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
                .onChange(of: vm.isGenerating) { _, _ in
                    if vm.isGenerating {
                        withAnimation { proxy.scrollTo("loading", anchor: .bottom) }
                    }
                }
            }

            VStack(spacing: 12) {
                HStack {
                    Menu {
                        ForEach(vm.craftReadPrompts, id: \.label) { prompt in
                            Button(prompt.label) {
                                vm.chatInput = prompt.value
                                vm.sendChatMessage(documentText: documentText)
                            }
                        }
                    } label: {
                        Image(systemName: "wand.and.stars.inverse")
                            .font(.title3)
                            .foregroundColor(.pink)
                    }

                    TextField("Ask anything...", text: $vm.chatInput)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { vm.sendChatMessage(documentText: documentText) }

                    Button {
                        vm.sendChatMessage(documentText: documentText)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(vm.chatInput.isEmpty || vm.isGenerating ? .secondary : .pink)
                    }
                    .disabled(vm.chatInput.isEmpty || vm.isGenerating)
                }
            }
            .padding(.top, 12)
        }
        .frame(maxHeight: 600)
    }

    struct ComplexityBar: View {
        let label: String
        let value: CGFloat
        let color: Color

        var body: some View {
            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
                    .frame(width: 40, height: 80 * value)
                Text(label).font(.system(size: 8)).foregroundStyle(.secondary)
                Text("\(Int(value * 100))%").font(.system(size: 10, weight: .bold))
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helpers
    private func statTile(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline.bold())
        }
    }

    private func scaleRow(score: String, label: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(score).font(.caption.monospaced()).frame(width: 50, alignment: .leading)
            Text(label).font(.caption)
            Spacer()
        }
    }

    private func toneRow(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label).font(.caption)
                Spacer()
                Text("\(Int(value))%").font(.caption.bold())
            }
            ProgressView(value: value, total: 100)
                .accentColor(color)
        }
    }

    private func complexityRow(label: String, count: Int, total: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label).font(.caption)
                Spacer()
                Text("\(count) (\(total > 0 ? Int(Double(count)/Double(total)*100) : 0)%)").font(.caption.bold())
            }
            ProgressView(value: Double(count), total: Double(max(1, total)))
                .accentColor(color)
        }
    }

    private func severityBadge(label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.caption2.bold())
            Text("\(count)").font(.caption2.bold()).padding(.horizontal, 4).background(Color.white.opacity(0.3)).cornerRadius(4)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(8)
    }

    private func chatBubble(message: AnalyticsChatMessage) -> some View {
        HStack {
            if message.role == "user" { Spacer() }

            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                Text(LocalizedStringKey(message.content))
                    .padding(12)
                    .background(message.role == "user" ? Color.purple : Color.secondary.opacity(0.1))
                    .foregroundColor(message.role == "user" ? .white : .primary)
                    .cornerRadius(16)

                Text(message.timestamp, style: .time)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }

            if message.role == "assistant" { Spacer() }
        }
        .id(message.id)
    }

    private func toneRecommendation(for tone: String) -> String {
        switch tone.lowercased() {
        case "positive": return "Your tone is very upbeat! Ensure it matches the gravity of your subject matter."
        case "negative": return "Your writing has a negative slant. Consider if a more constructive tone would be better."
        case "analytical": return "Great analytical tone. Consider adding a bit more personality to make it more accessible."
        case "confident": return "You sound very sure of yourself! This is great for persuasive writing."
        case "tentative": return "You sound a bit uncertain. Try using more definitive language if you want to be persuasive."
        default: return "Your tone is quite neutral. This is good for reporting facts clearly."
        }
    }

    private func structureRecommendation(avg: Double) -> String {
        if avg > 25 { return "Your average sentence is quite long. Try mixing in shorter sentences to create a better rhythm." }
        if avg < 12 { return "Your sentences are mostly short. Try connecting some ideas to create a more sophisticated flow." }
        return "Your sentence length variety is within an ideal range for most readers."
    }

    private func heatmapColor(for length: Int) -> Color {
        if length < 10 { return .green.opacity(0.6) }
        if length < 20 { return .blue.opacity(0.6) }
        if length < 30 { return .orange.opacity(0.6) }
        return .red.opacity(0.6)
    }

    struct GoalRow: View {
        let title: String
        let current: Double
        let goal: Double
        let unit: String

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title).font(.subheadline.bold())
                    Spacer()
                    Text("\(Int(current)) / \(Int(goal)) \(unit)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: min(current, goal), total: goal)
                    .tint(current >= goal ? .green : .accentColor)
            }
        }
    }

    // MARK: - Writing Score Card

    private var computedWritingScore: Int {
        var score = 50
        let readability = vm.stats.readabilityScore
        if readability >= 60 && readability <= 80 { score += 15 }
        else if readability >= 40 { score += 8 }
        let avgSentence = vm.stats.averageSentenceLength
        if avgSentence >= 12 && avgSentence <= 22 { score += 15 }
        else if avgSentence >= 8 { score += 5 }
        let density = vm.stats.lexicalDensity
        if density >= 40 && density <= 65 { score += 10 }
        if vm.stats.paragraphCount >= 3 { score += 5 }
        if vm.stats.wordCount >= 200 { score += 5 }
        return min(100, score)
    }

    private var scoreGrade: (letter: String, color: Color) {
        let s = computedWritingScore
        if s >= 90 { return ("A+", .green) }
        if s >= 80 { return ("A", .green) }
        if s >= 70 { return ("B", .blue) }
        if s >= 60 { return ("C", .orange) }
        if s >= 50 { return ("D", .red) }
        return ("F", .red)
    }

    private var writingScoreCard: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Writing Score", systemImage: "star.fill")
                    .font(.headline)
                    .foregroundStyle(.indigo)
                Spacer()
                Text(scoreGrade.letter)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(scoreGrade.color)
            }

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 8)
                        .frame(width: 72, height: 72)
                    Circle()
                        .trim(from: 0, to: CGFloat(computedWritingScore) / 100)
                        .stroke(scoreGrade.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))
                    Text("\(computedWritingScore)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }

                VStack(alignment: .leading, spacing: 6) {
                    scoreMetricRow("Readability", value: vm.stats.readabilityScore, target: comparisonBaseline.targetReadability)
                    scoreMetricRow("Sentence Flow", value: vm.stats.averageSentenceLength, target: comparisonBaseline.targetSentenceLength)
                    scoreMetricRow("Vocabulary", value: vm.stats.lexicalDensity, target: 55)
                }
            }
        }
        .padding()
        .background(Color.indigo.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
    }

    private func scoreMetricRow(_ label: String, value: Double, target: Double) -> some View {
        HStack(spacing: 6) {
            let delta = value - target
            Image(systemName: abs(delta) < 10 ? "checkmark.circle.fill" : (delta > 0 ? "arrow.up.circle" : "arrow.down.circle"))
                .font(.caption2)
                .foregroundStyle(abs(delta) < 10 ? .green : .orange)
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Spacer()
            Text(String(format: "%.0f", value)).font(.caption2.bold())
            Text("/ \(String(format: "%.0f", target))").font(.system(size: 8)).foregroundStyle(.secondary)
        }
    }

    // MARK: - Baseline Comparison Card

    private var baselineComparisonCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Baseline: \(comparisonBaseline.rawValue)", systemImage: "ruler")
                    .font(.caption.bold())
                Spacer()
                Menu {
                    ForEach(WritingBaseline.allCases, id: \.rawValue) { b in
                        Button(b.rawValue) { comparisonBaseline = b }
                    }
                } label: {
                    Text("Change").font(.caption2.bold()).foregroundStyle(Color.accentColor)
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                GridRow {
                    Text("Metric").font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                    Text("Yours").font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                    Text("Target").font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                    Text("Status").font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
                }
                Divider()
                GridRow {
                    Text("Readability").font(.caption2)
                    Text(String(format: "%.0f", vm.stats.readabilityScore)).font(.caption2.bold())
                    Text(String(format: "%.0f", comparisonBaseline.targetReadability)).font(.caption2)
                    baselineStatusIcon(value: vm.stats.readabilityScore, target: comparisonBaseline.targetReadability)
                }
                GridRow {
                    Text("Avg Sentence").font(.caption2)
                    Text(String(format: "%.1f", vm.stats.averageSentenceLength)).font(.caption2.bold())
                    Text(String(format: "%.0f", comparisonBaseline.targetSentenceLength)).font(.caption2)
                    baselineStatusIcon(value: vm.stats.averageSentenceLength, target: comparisonBaseline.targetSentenceLength)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }

    private func baselineStatusIcon(value: Double, target: Double) -> some View {
        let delta = abs(value - target)
        let pct = target > 0 ? delta / target : 0
        if pct < 0.15 {
            return Image(systemName: "checkmark.circle.fill").font(.caption2).foregroundStyle(.green)
        } else if pct < 0.35 {
            return Image(systemName: "arrow.triangle.2.circlepath").font(.caption2).foregroundStyle(.orange)
        } else {
            return Image(systemName: "exclamationmark.triangle.fill").font(.caption2).foregroundStyle(.red)
        }
    }
}

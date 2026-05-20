import SwiftUI

struct WritingAnalyticsView: View {
    let documentText: String
    let documentTitle: String
    @Binding var isPresented: Bool
    @StateObject private var vm = WritingAnalyticsViewModel()

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
            }
            .onAppear {
                vm.runAnalysis(text: documentText)
            }
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
            WorkspaceSurfaceCard {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    statTile(label: "Words", value: "\(vm.stats.wordCount)", icon: "text.wordspacing", color: .blue)
                    statTile(label: "Characters", value: "\(vm.stats.charCount)", icon: "character", color: .green)
                    statTile(label: "Sentences", value: "\(vm.stats.sentenceCount)", icon: "text.quote", color: .orange)
                    statTile(label: "Paragraphs", value: "\(vm.stats.paragraphCount)", icon: "paragraph", color: .purple)
                }
                .padding()
            }

            SectionCard(title: "Document Details") {
                VStack(spacing: 12) {
                    detailRow(label: "Avg. Words / Sentence", value: String(format: "%.1f", vm.stats.avgWordsPerSentence))
                    Divider()
                    detailRow(label: "Avg. Words / Paragraph", value: String(format: "%.1f", vm.stats.avgWordsPerParagraph))
                    Divider()
                    detailRow(label: "Estimated Read Time", value: "\(Int(ceil(Double(vm.stats.wordCount) / 200.0))) min")
                }
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
            VStack(spacing: 8) {
                Text("\(Int(vm.stats.readabilityScore))")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(.green)
                Text("Flesch Reading Ease")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 4) {
                Text(level.level).font(.title2.bold())
                Text("Grade Level: \(vm.stats.gradeLevel)").font(.headline).foregroundColor(.secondary)
                Text(level.cefr).font(.subheadline).foregroundColor(.secondary)
            }

            ProgressView(value: vm.stats.readabilityScore, total: 100)
                .accentColor(.green)
                .scaleEffect(x: 1, y: 2, anchor: .center)

            HStack(spacing: 16) {
                statTile(label: "CEFR Level", value: level.cefr, icon: "graduationcap", color: .blue)
                statTile(label: "Grade Level", value: vm.stats.gradeLevel, icon: "text.book.closed", color: .orange)
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
            if let arg = vm.argumentAnalysis {
                SectionCard(title: "Argument Strength") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Strength Score")
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
                                Text("• \(gap)").font(.caption).foregroundColor(.red)
                            }
                        }
                    }
                }
            }

            VStack(spacing: 8) {
                Text(vm.tone.primary)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.orange)
                Text("\(Int(vm.tone.confidence))% Confidence")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: vm.tone.confidence, total: 100)
                .accentColor(.orange)

            VStack(alignment: .leading, spacing: 16) {
                Text("Emotional Breakdown").font(.headline)
                toneRow(label: "Positive", value: vm.tone.positive, color: .green)
                toneRow(label: "Negative", value: vm.tone.negative, color: .red)
                toneRow(label: "Neutral", value: vm.tone.neutral, color: .gray)
                toneRow(label: "Analytical", value: vm.tone.analytical, color: .blue)
                toneRow(label: "Confident", value: vm.tone.confident, color: .purple)
                toneRow(label: "Tentative", value: vm.tone.tentative, color: .orange)
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
            HStack(spacing: 16) {
                statTile(label: "Unique Words", value: "\(vm.stats.uniqueWordCount)", icon: "character.bubble", color: .blue)
                statTile(label: "Richness", value: String(format: "%.1f%%", vm.stats.vocabularyRichness), icon: "chart.pie", color: .indigo)
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
                Text("Word Complexity").font(.headline)
                complexityRow(label: "Simple", count: vm.complexity.simple, total: vm.stats.wordCount, color: .green)
                complexityRow(label: "Moderate", count: vm.complexity.moderate, total: vm.stats.wordCount, color: .orange)
                complexityRow(label: "Complex", count: vm.complexity.complex, total: vm.stats.wordCount, color: .red)
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
}

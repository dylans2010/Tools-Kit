import SwiftUI

struct CodeHomeView: View {
    @StateObject private var analyzer = CodeAnalyzer()
    @State private var showAudit = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "link")
                        Text("https://github.com/dylans2010/SwiftCode")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Target Repository")
                }

                Section {
                    if analyzer.isAnalyzing {
                        HStack {
                            ProgressView()
                            Text("Analyzing repository...")
                                .padding(.leading, 8)
                        }
                    } else if let result = analyzer.auditResult {
                        NavigationLink(destination: CodeAuditView(analyzer: analyzer)) {
                            Label("View Audit (\(result.files.count) files)", systemImage: "doc.text.magnifyingglass")
                        }

                        NavigationLink(destination: CodeImportPlanView(analyzer: analyzer)) {
                            Label("View Import Plan (\(analyzer.importPlan.count) actions)", systemImage: "list.bullet.clipboard")
                        }
                    } else {
                        Text("No analysis performed yet.")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Status")
                }

                Section {
                    Button(action: {
                        Task {
                            await analyzer.analyze(owner: "dylans2010", repo: "SwiftCode")
                        }
                    }) {
                        HStack {
                            Spacer()
                            if analyzer.isAnalyzing {
                                Text("Analyzing...")
                            } else {
                                Text("Analyze SwiftCode Repo")
                            }
                            Spacer()
                        }
                    }
                    .disabled(analyzer.isAnalyzing)
                    .buttonStyle(.borderedProminent)
                }
            }
            .aiAnimationLoading(analyzer.isAnalyzing)
            .navigationTitle("Code Workspace")
        }
    }
}

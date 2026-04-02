import SwiftUI

struct IdeaGeneratorView: View {
    @StateObject private var backend = IdeaGeneratorBackend()

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "lightbulb.stars.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                    .shadow(radius: 5)

                Text("Need Inspiration?")
                    .font(.title2).bold()

                Text("Generate random startup and project ideas based on trending niches and technologies.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top)

            Button(action: backend.generate) {
                Label("Generate New Idea", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            List {
                Section(header: Text("Recent Ideas")) {
                    if backend.ideas.isEmpty {
                        Text("No ideas yet. Tap the button!").foregroundColor(.secondary)
                    } else {
                        ForEach(backend.ideas, id: \.self) { idea in
                            HStack {
                                Text(idea)
                                Spacer()
                                Button(action: { UIPasteboard.general.string = idea }) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())

            if !backend.ideas.isEmpty {
                Button("Clear History", role: .destructive) {
                    backend.clear()
                }
                .padding(.bottom)
            }
        }
        .navigationTitle("Idea Generator")
    }
}

struct IdeaGeneratorTool: Tool {
    let name = "Idea Generator"
    let icon = "lightbulb.fill"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.basic
    let description = "Generate innovative app and business ideas"
    let requiresAPI = false
    var view: AnyView { AnyView(IdeaGeneratorView()) }
}

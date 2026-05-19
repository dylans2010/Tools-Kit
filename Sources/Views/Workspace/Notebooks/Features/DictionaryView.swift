import SwiftUI

struct DictionaryView: View {
    @Binding var isPresented: Bool
    var onInsert: ((String) -> Void)? = nil
    @StateObject private var vm = DictionaryViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar

                if vm.isLoading {
                    ProgressView().padding(.top, 40)
                    Spacer()
                } else if let error = vm.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundColor(.secondary)
                        Text(error).foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    Spacer()
                } else if let result = vm.result {
                    resultView(result)
                } else {
                    recentSearchesView
                }
            }
            .navigationTitle("Dictionary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { isPresented = false }
                }
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("Search a word...", text: $vm.searchText)
                .textFieldStyle(.plain)
                .onSubmit {
                    Task { await vm.search(word: vm.searchText) }
                }
            if !vm.searchText.isEmpty {
                Button { vm.searchText = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.secondary) }
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }

    private var recentSearchesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !vm.recentSearches.isEmpty {
                Text("Recent Searches").font(.headline).padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(vm.recentSearches, id: \.self) { word in
                            Button {
                                Task { await vm.search(word: word) }
                            } label: {
                                Text(word)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(15)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            Spacer()
        }
    }

    private func resultView(_ result: DictionaryResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.word).font(.system(size: 40, weight: .bold))
                        if let phonetic = result.phonetic {
                            Text(phonetic).font(.title3).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Button {
                        vm.playAudio()
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                }

                ForEach(result.meanings) { meaning in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(meaning.partOfSpeech.capitalized)
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(partOfSpeechColor(meaning.partOfSpeech).opacity(0.1))
                            .foregroundColor(partOfSpeechColor(meaning.partOfSpeech))
                            .cornerRadius(8)

                        ForEach(Array(meaning.definitions.enumerated()), id: \.offset) { index, def in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(index + 1). \(def.definition)")
                                    .font(.body)

                                if let example = def.example {
                                    Text("\"\(example)\"")
                                        .font(.subheadline.italic())
                                        .foregroundColor(.secondary)
                                }

                                if !def.synonyms.isEmpty {
                                    wordChipGroup(title: "Synonyms", words: def.synonyms)
                                }

                                if !def.antonyms.isEmpty {
                                    wordChipGroup(title: "Antonyms", words: def.antonyms)
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(12)
                }

                if !result.sourceUrls.isEmpty {
                    DisclosureGroup("Sources") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(result.sourceUrls, id: \.self) { url in
                                Link(url, destination: URL(string: url)!)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.top, 8)
                    }
                }

                Button {
                    if let firstDef = result.meanings.first?.definitions.first?.definition,
                       let pos = result.meanings.first?.partOfSpeech {
                        onInsert?("**\(result.word)** *(\(pos))* : \(firstDef)")
                        isPresented = false
                    }
                } label: {
                    Text("Insert to Page")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top, 20)
            }
            .padding()
        }
    }

    private func wordChipGroup(title: String, words: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption.bold()).foregroundColor(.secondary)
            FlowLayout(words, spacing: 8) { word in
                Button {
                    Task { await vm.search(word: word) }
                } label: {
                    Text(word)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }

    private func partOfSpeechColor(_ pos: String) -> Color {
        switch pos.lowercased() {
        case "noun": return .blue
        case "verb": return .green
        case "adjective": return .orange
        case "adverb": return .purple
        default: return .secondary
        }
    }
}


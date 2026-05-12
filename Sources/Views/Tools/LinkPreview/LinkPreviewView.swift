import SwiftUI

struct LinkPreviewView: View {
    @StateObject private var backend = LinkPreviewBackend()

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                TextField("Enter URL", text: $backend.urlString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                Button(action: backend.fetch) {
                    if backend.isLoading {
                        ProgressView()
                    } else {
                        Text("Preview")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(backend.isLoading || backend.urlString.isEmpty)
            }
            .padding(.horizontal)

            if let error = backend.error {
                Text(error).foregroundColor(.red).font(.caption)
            }

            if let meta = backend.metadata {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        if let icon = meta.icon {
                            Image(uiImage: icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .cornerRadius(8)
                        } else {
                            Image(systemName: "link.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        }

                        VStack(alignment: .leading) {
                            Text(meta.title ?? "No Title")
                                .font(.headline)
                                .lineLimit(2)
                            Text(meta.url.host ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    Text(meta.url.absoluteString)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .onTapGesture {
                            UIPasteboard.general.url = meta.url
                        }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding()
            } else if !backend.isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "link")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Generate Preview")
                        .font(.headline)
                    Text("Enter a URL to see its metadata and preview.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Link Preview")
    }
}

struct LinkPreviewTool: Tool, Sendable {
    let name = "Link Preview"
    let icon = "link.circle.fill"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Generate a rich preview and metadata for any web link"
    let requiresAPI = true
    var view: AnyView { AnyView(LinkPreviewView()) }
}

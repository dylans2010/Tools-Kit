import SwiftUI

struct WebsiteScreenshotView: View {
    @StateObject private var backend = WebsiteScreenshotBackend()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    TextField("Enter Website URL", text: $backend.urlString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Button(action: backend.capture) {
                        if backend.isLoading {
                            ProgressView()
                        } else {
                            Text("Capture")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(backend.isLoading || backend.urlString.isEmpty)
                }
                .padding(.horizontal)

                if let error = backend.error {
                    Text(error).foregroundColor(.red).font(.caption)
                }

                if let image = backend.screenshot {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Screenshot Result").font(.headline)
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                            .shadow(radius: 5)

                        ShareLink(item: Image(uiImage: image), preview: SharePreview("Website Screenshot", image: Image(uiImage: image))) {
                            Label("Save / Share Screenshot", systemImage: "square.and.arrow.up")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                } else if !backend.isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "safari")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Ready to Capture")
                            .font(.headline)
                        Text("Enter a URL and tap Capture to generate a full-page screenshot.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                }
            }
            .padding()
        }
        .navigationTitle("Website Screenshot")
    }
}

struct WebsiteScreenshotTool: Tool {
    let name = "Website Screenshot"
    let icon = "web.viewfinder"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Generate a full-page screenshot of any website"
    let requiresAPI = true
    var view: AnyView { AnyView(WebsiteScreenshotView()) }
}

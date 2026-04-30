import SwiftUI

/// Advanced presentation runtime view with multi-screen support and presenter tools.
struct PresentationRuntimeView: View {
    @ObservedObject var runtime = AnimationRuntime.shared
    let slides: [Slide]

    @State private var showPresenterNotes = false
    @State private var currentSlideIndex = 0

    private var currentSlide: Slide? {
        guard slides.indices.contains(currentSlideIndex) else { return nil }
        return slides[currentSlideIndex]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let slide = currentSlide {
                SlideContentView(slide: slide)
                    .transition(.opacity)
                    .id(slide.id)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            presenterControls
        }
        .sheet(isPresented: $showPresenterNotes) {
            presenterNotesSheet
        }
    }

    private var presenterControls: some View {
        HStack {
            Button("Notes") { showPresenterNotes.toggle() }
            Button("Prev") { currentSlideIndex -= 1 }
            Button("Next") { currentSlideIndex += 1 }
        }
        .padding()
        .background(.ultraThinMaterial, in: Capsule())
        .padding()
    }

    private var presenterNotesSheet: some View {
        NavigationStack {
            Text("Presenter notes for slide \(currentSlideIndex + 1)...")
                .padding()
                .navigationTitle("Presenter Notes")
        }
    }
}

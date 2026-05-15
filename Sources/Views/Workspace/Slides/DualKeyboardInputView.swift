import SwiftUI

/// A unified dual-layer keyboard extension that visually appears as a single component.
/// Layer 1: Primary text input for the active field (prompt / notes / documents).
/// Layer 2: Secondary controls (field switcher, tone, slide count, style & theme presets).
///
/// This view is the **sole** input mechanism for AIGenerateSlides – all text editing is
/// routed through the TextField here so the system keyboard renders behind the gradient
/// glow backdrop managed by the Aurora sheet system.
struct DualKeyboardInputView: View {
    @Binding var promptText: String
    @Binding var notesText: String
    @Binding var documentsText: String
    @Binding var activeField: SlideInputField
    @Binding var tone: SlideTone
    @Binding var slideCount: Int
    @Binding var selectedStyleID: String
    @Binding var selectedThemeID: String
    var onSubmit: () -> Void

    @ObservedObject var keyboard: KeyboardObserver
    @FocusState.Binding var isFocused: Bool
    @State private var animateIn = false

    // Binding to the currently-active text field
    private var activeTextBinding: Binding<String> {
        switch activeField {
        case .prompt: return $promptText
        case .notes: return $notesText
        case .documents: return $documentsText
        }
    }

    init(
        promptText: Binding<String>,
        notesText: Binding<String>,
        documentsText: Binding<String>,
        activeField: Binding<SlideInputField>,
        tone: Binding<SlideTone>,
        slideCount: Binding<Int>,
        selectedStyleID: Binding<String>,
        selectedThemeID: Binding<String>,
        onSubmit: @escaping () -> Void,
        keyboard: KeyboardObserver,
        isFocused: FocusState<Bool>.Binding
    ) {
        self._promptText = promptText
        self._notesText = notesText
        self._documentsText = documentsText
        self._activeField = activeField
        self._tone = tone
        self._slideCount = slideCount
        self._selectedStyleID = selectedStyleID
        self._selectedThemeID = selectedThemeID
        self.onSubmit = onSubmit
        self.keyboard = keyboard
        self._isFocused = isFocused
    }

    var body: some View {
        VStack(spacing: 0) {
            if keyboard.isVisible {
                unifiedContainer
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: keyboard.isVisible)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.3)) { animateIn = true }
                    }
                    .onDisappear { animateIn = false }
            }

            // Hidden focus-holder: always present so the keyboard can be summoned
            focusTriggerField
        }
    }

    // MARK: - Focus Trigger

    /// A minimal, invisible TextField that holds first-responder status.
    /// Tapping the field-selector chips or the container refocuses here.
    private var focusTriggerField: some View {
        TextField("", text: activeTextBinding, axis: .vertical)
            .focused($isFocused)
            .lineLimit(1...4)
            .font(.subheadline)
            .frame(height: 0)
            .opacity(0)
            .allowsHitTesting(false)
    }

    // MARK: - Unified Container

    private var unifiedContainer: some View {
        VStack(spacing: 0) {
            primaryInputLayer
            secondaryControlLayer
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.systemIndigo).opacity(0.30),
                            Color(.systemPurple).opacity(0.24),
                            Color(.systemCyan).opacity(0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 12)
    }

    // MARK: - Primary Input Layer

    private var primaryInputLayer: some View {
        VStack(spacing: 6) {
            // Active-field label
            HStack {
                Image(systemName: activeField.icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(activeField.label)
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField(activeField.placeholder, text: activeTextBinding, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(uiColor: .systemBackground).opacity(0.6))
                    )
                    .focused($isFocused)

                Button(action: onSubmit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(.systemIndigo), Color(.systemPurple)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .disabled(promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.bottom, 10)
    }

    // MARK: - Secondary Control Layer

    private var secondaryControlLayer: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                fieldSwitcherChips
                toneChip
                slideCountChip
                themePresetChips
                stylePresetChips
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Field Switcher Chips

    private var fieldSwitcherChips: some View {
        ForEach(SlideInputField.allCases, id: \.self) { field in
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    activeField = field
                }
                isFocused = true
            } label: {
                chipLabel(
                    icon: field.icon,
                    text: field.label,
                    isActive: activeField == field
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var toneChip: some View {
        Menu {
            ForEach(SlideTone.allCases, id: \.self) { option in
                Button(option.rawValue.capitalized) { tone = option }
            }
        } label: {
            chipLabel(icon: "waveform", text: tone.rawValue.capitalized)
        }
    }

    private var slideCountChip: some View {
        Menu {
            ForEach(5...15, id: \.self) { count in
                Button("\(count) slides") { slideCount = count }
            }
        } label: {
            chipLabel(icon: "square.stack", text: "\(slideCount) slides")
        }
    }

    private var themePresetChips: some View {
        ForEach(AIGenSlideCatalog.themes.prefix(4)) { theme in
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedThemeID = theme.id
                }
            } label: {
                chipLabel(
                    icon: "paintpalette",
                    text: theme.name,
                    isActive: selectedThemeID == theme.id
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var stylePresetChips: some View {
        ForEach(AIGenSlideCatalog.styles.prefix(4)) { style in
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedStyleID = style.id
                }
            } label: {
                chipLabel(
                    icon: "paintbrush",
                    text: style.name,
                    isActive: selectedStyleID == style.id
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func chipLabel(icon: String, text: String, isActive: Bool = false) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isActive ? Color(.systemIndigo).opacity(0.2) : Color(.systemGray5).opacity(0.8))
        )
        .overlay(
            Capsule()
                .stroke(isActive ? Color(.systemIndigo).opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .foregroundStyle(isActive ? Color(.systemIndigo) : .primary)
    }
}

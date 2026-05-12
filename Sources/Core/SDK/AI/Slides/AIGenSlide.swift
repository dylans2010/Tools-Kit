import Foundation

public enum ContrastMode: String, Codable, CaseIterable, Sendable {
    case standard
    case high
}

public enum VisualDensity: String, Codable, CaseIterable, Sendable {
    case minimal
    case balanced
    case dense
}

public enum AnimationLevel: String, Codable, CaseIterable, Sendable {
    case none
    case subtle
    case dynamic
}

public enum ImageStyle: String, Codable, CaseIterable, Sendable {
    case photo
    case illustration
    case abstract
    case mixed
}

public struct SlideTheme: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var gradient: [String]
    public var font: String
    public var glassEffect: Bool
    public var contrastMode: ContrastMode
    public var blurIntensity: Double
    public var glowLevel: Double
    public var fontPairing: [String]

    public init(
        id: String,
        name: String,
        gradient: [String],
        font: String,
        glassEffect: Bool,
        contrastMode: ContrastMode,
        blurIntensity: Double,
        glowLevel: Double,
        fontPairing: [String]
    ) {
        self.id = id
        self.name = name
        self.gradient = gradient
        self.font = font
        self.glassEffect = glassEffect
        self.contrastMode = contrastMode
        self.blurIntensity = blurIntensity
        self.glowLevel = glowLevel
        self.fontPairing = fontPairing
    }
}

public struct SlideStyle: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var visualDensity: VisualDensity
    public var animationLevel: AnimationLevel
    public var imageStyle: ImageStyle

    public init(
        id: String,
        name: String,
        visualDensity: VisualDensity,
        animationLevel: AnimationLevel,
        imageStyle: ImageStyle
    ) {
        self.id = id
        self.name = name
        self.visualDensity = visualDensity
        self.animationLevel = animationLevel
        self.imageStyle = imageStyle
    }
}

public enum AIGenSlideCatalog: Sendable {
    public static let defaultThemeID = "aurora-glass"
    public static let defaultStyleID = "corporate-minimal"

    public static let themes: [SlideTheme] = [
        .init(id: "aurora-glass", name: "Aurora Glass", gradient: ["#1D2B64", "#F8CDDA"], font: "SF Pro", glassEffect: true, contrastMode: .standard, blurIntensity: 0.72, glowLevel: 0.44, fontPairing: ["SF Pro Display", "SF Pro Text"]),
        .init(id: "neon-pulse", name: "Neon Pulse", gradient: ["#0F0C29", "#302B63", "#24243E"], font: "Avenir Next", glassEffect: true, contrastMode: .high, blurIntensity: 0.66, glowLevel: 0.90, fontPairing: ["Avenir Next Demi", "Avenir Next"]),
        .init(id: "midnight-drift", name: "Midnight Drift", gradient: ["#0B132B", "#1C2541"], font: "SF Pro", glassEffect: true, contrastMode: .high, blurIntensity: 0.60, glowLevel: 0.36, fontPairing: ["SF Pro Display", "Georgia"]),
        .init(id: "sunset-haze", name: "Sunset Haze", gradient: ["#355C7D", "#F67280", "#F8B195"], font: "Avenir", glassEffect: true, contrastMode: .standard, blurIntensity: 0.58, glowLevel: 0.48, fontPairing: ["Avenir Heavy", "Avenir Book"]),
        .init(id: "arctic-light", name: "Arctic Light", gradient: ["#E3F2FD", "#90CAF9"], font: "Helvetica Neue", glassEffect: true, contrastMode: .standard, blurIntensity: 0.50, glowLevel: 0.22, fontPairing: ["Helvetica Neue Bold", "Helvetica Neue"]),
        .init(id: "cyber-grid", name: "Cyber Grid", gradient: ["#0F2027", "#203A43", "#2C5364"], font: "Menlo", glassEffect: true, contrastMode: .high, blurIntensity: 0.68, glowLevel: 0.84, fontPairing: ["Menlo Bold", "SF Mono"]),
        .init(id: "ocean-depth", name: "Ocean Depth", gradient: ["#134E5E", "#71B280"], font: "Gill Sans", glassEffect: true, contrastMode: .standard, blurIntensity: 0.54, glowLevel: 0.30, fontPairing: ["Gill Sans Semibold", "Gill Sans"]),
        .init(id: "lavender-mist", name: "Lavender Mist", gradient: ["#8E2DE2", "#C471ED"], font: "Avenir", glassEffect: true, contrastMode: .standard, blurIntensity: 0.62, glowLevel: 0.40, fontPairing: ["Avenir Medium", "Avenir"]),
        .init(id: "volcanic-glow", name: "Volcanic Glow", gradient: ["#360033", "#0B8793"], font: "Futura", glassEffect: true, contrastMode: .high, blurIntensity: 0.57, glowLevel: 0.75, fontPairing: ["Futura Bold", "Futura"]),
        .init(id: "forest-neon", name: "Forest Neon", gradient: ["#11998E", "#38EF7D"], font: "SF Pro", glassEffect: true, contrastMode: .high, blurIntensity: 0.56, glowLevel: 0.62, fontPairing: ["SF Pro Rounded Semibold", "SF Pro Text"]),
        .init(id: "starlight-minimal", name: "Starlight Minimal", gradient: ["#232526", "#414345"], font: "Inter", glassEffect: false, contrastMode: .high, blurIntensity: 0.30, glowLevel: 0.18, fontPairing: ["Inter SemiBold", "Inter"]),
        .init(id: "rose-quartz", name: "Rose Quartz", gradient: ["#ED4264", "#FFEDBC"], font: "Avenir", glassEffect: true, contrastMode: .standard, blurIntensity: 0.52, glowLevel: 0.34, fontPairing: ["Avenir Black", "Avenir"])
    ]

    public static let styles: [SlideStyle] = [
        .init(id: "corporate-minimal", name: "Corporate Minimal", visualDensity: .minimal, animationLevel: .none, imageStyle: .photo),
        .init(id: "investor-pitch", name: "Investor Pitch", visualDensity: .balanced, animationLevel: .subtle, imageStyle: .mixed),
        .init(id: "academic-formal", name: "Academic Formal", visualDensity: .dense, animationLevel: .none, imageStyle: .illustration),
        .init(id: "startup-bold", name: "Startup Bold", visualDensity: .balanced, animationLevel: .dynamic, imageStyle: .mixed),
        .init(id: "creative-portfolio", name: "Creative Portfolio", visualDensity: .balanced, animationLevel: .subtle, imageStyle: .abstract),
        .init(id: "technical-deep-dive", name: "Technical Deep Dive", visualDensity: .dense, animationLevel: .none, imageStyle: .illustration),
        .init(id: "product-demo", name: "Product Demo", visualDensity: .balanced, animationLevel: .subtle, imageStyle: .photo),
        .init(id: "marketing-deck", name: "Marketing Deck", visualDensity: .balanced, animationLevel: .dynamic, imageStyle: .photo),
        .init(id: "visionary-futuristic", name: "Visionary Futuristic", visualDensity: .balanced, animationLevel: .dynamic, imageStyle: .abstract),
        .init(id: "data-heavy", name: "Data Heavy", visualDensity: .dense, animationLevel: .none, imageStyle: .illustration),
        .init(id: "story-driven", name: "Story Driven", visualDensity: .minimal, animationLevel: .subtle, imageStyle: .photo),
        .init(id: "design-showcase", name: "Design Showcase", visualDensity: .balanced, animationLevel: .dynamic, imageStyle: .mixed)
    ]
}

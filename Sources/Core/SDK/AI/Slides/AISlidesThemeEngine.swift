import Foundation

struct AISlidesThemeSelection: Sendable {
    var theme: SlideTheme
    var style: SlideStyle
    var isThemeScopeEnabled: Bool
}

struct AISlidesThemeEngine: Sendable {
    func availableThemes() -> [SlideTheme] {
        AIGenSlideCatalog.themes
    }

    func availableStyles() -> [SlideStyle] {
        AIGenSlideCatalog.styles
    }

    func resolveSelection(input: SlideInput, isThemeScopeEnabled: Bool) -> AISlidesThemeSelection {
        let themes = availableThemes()
        let styles = availableStyles()

        let theme = isThemeScopeEnabled
            ? themes.first(where: { $0.id == input.preferredThemeID }) ?? themes.first(where: { $0.id == AIGenSlideCatalog.defaultThemeID }) ?? themes[0]
            : themes.first(where: { $0.id == AIGenSlideCatalog.defaultThemeID }) ?? themes[0]

        let style = isThemeScopeEnabled
            ? styles.first(where: { $0.id == input.preferredStyleID }) ?? styles.first(where: { $0.id == AIGenSlideCatalog.defaultStyleID }) ?? styles[0]
            : styles.first(where: { $0.id == AIGenSlideCatalog.defaultStyleID }) ?? styles[0]

        return AISlidesThemeSelection(theme: theme, style: style, isThemeScopeEnabled: isThemeScopeEnabled)
    }
}

import Foundation

extension SlideDeck {
    func withTheme(_ theme: SlideTheme, style: SlideStyle) -> SlideDeck {
        var copy = self
        copy.theme = theme.id
        copy.slides = slides.map { slide in
            var s = slide
            s.metadata["themeID"] = theme.id
            s.metadata["themeName"] = theme.name
            s.metadata["styleID"] = style.id
            s.metadata["styleName"] = style.name
            s.metadata["font"] = theme.font
            s.metadata["contrastMode"] = theme.contrastMode.rawValue
            return s
        }
        return copy
    }
}

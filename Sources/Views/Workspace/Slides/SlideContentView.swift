import SwiftUI

struct SlideContentView: View {
    let slide: Slide

    var body: some View {
        ZStack {
            (Color(hex: slide.backgroundColorHex) ?? .black)

            ForEach(slide.elements) { element in
                ElementRenderer(element: element)
                    .position(x: element.x, y: element.y)
            }
        }
    }
}

struct ElementRenderer: View {
    let element: SlideElement

    var body: some View {
        Group {
            switch element.kind {
            case .text:
                Text(element.text)
                    .font(.system(size: element.fontSize, weight: element.fontWeight == "bold" ? .bold : .regular))
                    .foregroundColor(Color(hex: element.textColor) ?? .white)
            case .shape:
                Rectangle().fill(Color(hex: element.fillColor) ?? .blue)
            case .image:
                Image(systemName: "photo")
            }
        }
        .frame(width: element.width, height: element.height)
    }
}

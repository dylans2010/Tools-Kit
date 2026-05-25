import SwiftUI
import UIKit

struct SpinningWheelView: UIViewRepresentable {
    let rotation: Double

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let layer = CALayer()
        layer.frame = view.bounds
        layer.contents = UIImage(systemName: "circle.circle.fill")?.cgImage
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.toValue = rotation * Double.pi / 180
        animation.duration = 3.0
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        uiView.layer.add(animation, forKey: "rotate")
    }
}

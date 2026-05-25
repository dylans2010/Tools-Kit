import SwiftUI
import UIKit

struct SlotReelView: UIViewRepresentable {
    let symbols: [String]
    let finalIndex: Int
    @Binding var isSpinning: Bool

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(red: 26/255, green: 26/255, blue: 46/255, alpha: 1)
        container.layer.cornerRadius = 12
        container.clipsToBounds = true

        let label = UILabel()
        label.tag = 100
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 36)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let label = uiView.viewWithTag(100) as? UILabel else { return }
        if isSpinning {
            let anim = CABasicAnimation(keyPath: "transform.translation.y")
            anim.fromValue = -20
            anim.toValue = 20
            anim.duration = 0.08
            anim.repeatCount = .infinity
            anim.autoreverses = true
            label.layer.add(anim, forKey: "spin")
        } else {
            label.layer.removeAllAnimations()
            if finalIndex < symbols.count {
                label.text = symbols[finalIndex]
            }
        }
    }
}

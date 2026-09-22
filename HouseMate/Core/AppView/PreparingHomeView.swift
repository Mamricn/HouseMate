//
//  PreparingHomeView.swift
//  HouseMate
//

import SwiftUI
import UIKit

struct PreparingHomeView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        ZStack {
            launchBlue
                .ignoresSafeArea()

            VStack(spacing: 22) {
                logo

                VStack(spacing: 8) {
                    Text("Preparing your home")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Getting everything ready for you")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                }

                LaunchLoadingDots(reduceMotion: reduceMotion)
                    .frame(width: 49, height: 14)
                    .padding(.top, 4)
            }
        }
        .onAppear {
            StartupDiagnostics.mark("PreparingHomeView visible")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preparing your home")
    }

    private var logo: some View {
        ZStack {
            Image(systemName: "house.fill")
                .font(.system(size: 64, weight: .medium))
                .foregroundStyle(.white)

            Image(systemName: "person.2.fill")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(launchBlue)
                .offset(y: 10)
        }
        .shadow(color: .white.opacity(0.14), radius: 8)
    }

    private var launchBlue: Color {
        Color(
            red: 23 / 255,
            green: 105 / 255,
            blue: 245 / 255
        )
    }

}

private struct LaunchLoadingDots: UIViewRepresentable {

    let reduceMotion: Bool

    func makeUIView(context: Context) -> LaunchLoadingDotsView {
        LaunchLoadingDotsView(reduceMotion: reduceMotion)
    }

    func updateUIView(_ view: LaunchLoadingDotsView, context: Context) {
        view.setReduceMotion(reduceMotion)
    }
}

private final class LaunchLoadingDotsView: UIView {

    private let dots = (0..<3).map { _ in CAShapeLayer() }
    private var reduceMotion: Bool

    init(reduceMotion: Bool) {
        self.reduceMotion = reduceMotion
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        isAccessibilityElement = false

        dots.forEach {
            $0.fillColor = UIColor.white.cgColor
            layer.addSublayer($0)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()

        let diameter: CGFloat = 7
        let spacing: CGFloat = 7
        let totalWidth = (diameter * 3) + (spacing * 2)
        let startX = (bounds.width - totalWidth) / 2
        let y = (bounds.height - diameter) / 2

        for (index, dot) in dots.enumerated() {
            dot.path = UIBezierPath(
                ovalIn: CGRect(
                    x: startX + CGFloat(index) * (diameter + spacing),
                    y: y,
                    width: diameter,
                    height: diameter
                )
            ).cgPath
        }

        guard dots.first?.animation(forKey: "launchPulse") == nil else { return }
        updateAnimations()
    }

    func setReduceMotion(_ reduceMotion: Bool) {
        guard self.reduceMotion != reduceMotion else { return }
        self.reduceMotion = reduceMotion
        dots.forEach { $0.removeAllAnimations() }
        updateAnimations()
    }

    private func updateAnimations() {
        dots.forEach { $0.removeAllAnimations() }

        guard !reduceMotion else {
            dots.forEach { $0.opacity = 0.7 }
            return
        }

        for (index, dot) in dots.enumerated() {
            dot.opacity = 0.4

            let opacity = CABasicAnimation(keyPath: "opacity")
            opacity.fromValue = 0.4
            opacity.toValue = 1.0

            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = 0.65
            scale.toValue = 1.0

            let group = CAAnimationGroup()
            group.animations = [opacity, scale]
            group.duration = 0.72
            group.beginTime = CACurrentMediaTime() + (Double(index) * 0.16)
            group.autoreverses = true
            group.repeatCount = .infinity
            group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            group.isRemovedOnCompletion = false
            dot.add(group, forKey: "launchPulse")
        }
    }
}

#Preview("Preparing Home") {
    PreparingHomeView()
}

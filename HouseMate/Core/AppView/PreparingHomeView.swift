//
//  PreparingHomeView.swift
//  HouseMate
//

import SwiftUI

struct PreparingHomeView: View {

    @State private var isPulsing = false
    @State private var activeDot = 0

    var body: some View {
        ZStack {
            launchBlue
                .ignoresSafeArea()

            ambientGlow

            VStack(spacing: 22) {
                logo
                    .scaleEffect(isPulsing ? 1.04 : 0.96)
                    .shadow(
                        color: .white.opacity(isPulsing ? 0.24 : 0.1),
                        radius: isPulsing ? 18 : 8
                    )

                VStack(spacing: 8) {
                    Text("Preparing your home")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Getting everything ready for you")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                }

                loadingDots
                    .padding(.top, 4)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.15)
                    .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }

        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(360))

                guard !Task.isCancelled else { return }

                activeDot = (activeDot + 1) % 3
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preparing your home")
    }

    private var logo: some View {
        ZStack {
            Image(systemName: "house.fill")
                .font(.system(size: 64, weight: .medium))

            Image(systemName: "person.2.fill")
                .font(.system(size: 21, weight: .semibold))
                .offset(y: 10)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .foregroundStyle(.white)
    }

    private var loadingDots: some View {
        HStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(.white)
                    .frame(width: 7, height: 7)
                    .scaleEffect(activeDot == index ? 1 : 0.65)
                    .opacity(activeDot == index ? 1 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.25),
                        value: activeDot
                    )
            }
        }
        .accessibilityHidden(true)
    }

    private var ambientGlow: some View {
        ZStack {
            Circle()
                .fill(.cyan.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 75)
                .offset(x: -150, y: -300)

            Circle()
                .fill(.purple.opacity(0.22))
                .frame(width: 290, height: 290)
                .blur(radius: 85)
                .offset(x: 165, y: 325)
        }
    }

    private var launchBlue: Color {
        Color(
            red: 23 / 255,
            green: 105 / 255,
            blue: 245 / 255
        )
    }

}

#Preview("Preparing Home") {
    PreparingHomeView()
}

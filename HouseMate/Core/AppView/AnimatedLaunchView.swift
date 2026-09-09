//
//  AnimatedLaunchView.swift
//  HouseMate
//

import SwiftUI

struct AnimatedLaunchView: View {

    @State private var revealsBrand = false
    @State private var showsGlow = false

    var body: some View {
        ZStack {
            launchBlue
                .ignoresSafeArea()

            glow

            ZStack {
                logo
                    .offset(y: revealsBrand ? -54 : 0)
                    .scaleEffect(revealsBrand ? 1 : 0.72)
                    .opacity(revealsBrand ? 1 : 0)

                Text("HouseMate")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .offset(y: revealsBrand ? 54 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
                revealsBrand = true
            }

            withAnimation(.easeOut(duration: 1.1).delay(0.15)) {
                showsGlow = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("HouseMate")
    }

    private var logo: some View {
        ZStack {
            Image(systemName: "house.fill")
                .font(.system(size: 82, weight: .medium))

            Image(systemName: "person.2.fill")
                .font(.system(size: 27, weight: .semibold))
                .offset(y: 13)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .foregroundStyle(.white)
        .shadow(color: .white.opacity(0.18), radius: 14)
    }

    private var glow: some View {
        ZStack {
            Circle()
                .fill(.cyan.opacity(0.24))
                .frame(width: 280, height: 280)
                .blur(radius: 75)
                .offset(x: -155, y: -300)

            Circle()
                .fill(.purple.opacity(0.28))
                .frame(width: 300, height: 300)
                .blur(radius: 85)
                .offset(x: 170, y: 320)
        }
        .opacity(showsGlow ? 1 : 0)
    }

    private var launchBlue: Color {
        Color(
            red: 23 / 255,
            green: 105 / 255,
            blue: 245 / 255
        )
    }
}

#Preview("Animated Launch") {
    AnimatedLaunchView()
}

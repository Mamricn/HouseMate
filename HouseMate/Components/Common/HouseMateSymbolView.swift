//
//  HouseMateSymbolView.swift
//  HouseMate
//

import SwiftUI

struct HouseMateSymbolView: View {

    let systemName: String
    let color: Color

    var size: CGFloat = 42
    var symbolSize: CGFloat = 18

    var body: some View {
        Image(systemName: systemName)
            .font(
                .system(
                    size: symbolSize,
                    weight: .semibold
                )
            )
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background {
                RoundedRectangle(
                    cornerRadius: size * 0.32,
                    style: .continuous
                )
                .fill(color.opacity(0.12))
                .overlay {
                    RoundedRectangle(
                        cornerRadius: size * 0.32,
                        style: .continuous
                    )
                    .stroke(color.opacity(0.10), lineWidth: 0.75)
                }
            }
    }
}

#Preview {
    HStack {
        HouseMateSymbolView(
            systemName: "checklist",
            color: .blue
        )

        HouseMateSymbolView(
            systemName: "wrench.and.screwdriver.fill",
            color: .orange
        )
    }
    .padding()
}

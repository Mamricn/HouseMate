//
//  HouseholdFeatureTile.swift
//  HouseMate
//

import SwiftUI

struct HouseholdFeatureTile: View {

    let title: String
    let systemImage: String
    var assetName: String?
    let colors: [Color]
    var isLarge: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: isLarge ? 22 : 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colors.map { $0.opacity(0.16) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .fill(colors.last?.opacity(0.12) ?? .clear)
                    .frame(width: isLarge ? 92 : 68)
                    .offset(x: isLarge ? 48 : 35, y: isLarge ? -42 : -30)

                if let assetName {
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                        .padding(isLarge ? 7 : 6)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: isLarge ? 32 : 23, weight: .semibold))
                        .foregroundStyle(colors.first ?? .blue)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .frame(height: isLarge ? 118 : 76)
            .clipped()

            HStack(spacing: 6) {
                Text(title)
                    .font(isLarge ? .headline : .subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .frame(height: isLarge ? 48 : 42)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.55), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
    }
}

#Preview {
    HStack {
        HouseholdFeatureTile(
            title: "Bills",
            systemImage: "creditcard.fill",
            assetName: "HouseholdBills",
            colors: [.blue, .indigo],
            isLarge: true
        )

        HouseholdFeatureTile(
            title: "Cleaning",
            systemImage: "sparkles",
            assetName: "HouseholdCleaning",
            colors: [.cyan, .blue],
            isLarge: true
        )
    }
    .padding()
}

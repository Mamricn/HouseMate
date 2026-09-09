//
//  AppToastView.swift
//  HouseMate
//
//  Created by Marcin Turek on 21/08/2026.
//


import SwiftUI

struct AppToast: Identifiable {

    let id = UUID()
    let message: String
    let systemImage: String
    let color: Color
}

struct AppToastView: View {

    let toast: AppToast

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: toast.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(toast.color)

            Text(toast.message)
                .font(.footnote)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .stroke(
                            Color.primary.opacity(0.08),
                            lineWidth: 0.75
                        )
                }
        }
        .shadow(
            color: .black.opacity(0.08),
            radius: 8,
            y: 3
        )
        .padding(.horizontal, 24)
    }
}

#Preview {
    AppToastView(
        toast: AppToast(
            message: "Product added",
            systemImage: "cart.badge.plus",
            color: .green
        )
    )
}

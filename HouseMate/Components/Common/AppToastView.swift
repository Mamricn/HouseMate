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
        HStack(spacing: 12) {
            Image(systemName: toast.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(toast.color)

            Text(toast.message)
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            Capsule()
                .fill(.ultraThickMaterial)
                .overlay {
                    Capsule()
                        .stroke(
                            .white.opacity(0.35),
                            lineWidth: 1
                        )
                }
        }
        .shadow(
            color: .black.opacity(0.15),
            radius: 14,
            y: 7
        )
        .padding(.horizontal, 20)
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

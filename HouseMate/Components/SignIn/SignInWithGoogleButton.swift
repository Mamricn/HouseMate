//
//  SignInWithGoogleButton.swift
//  HouseMate
//
//  Created by Marcin Turek on 25/08/2026.
//



import SwiftUI

struct SignInWithGoogleButton: View {

    enum ColorScheme {
        case black
        case white
    }

    var colorScheme: ColorScheme = .white
    var action: () async throws -> Void

    var body: some View {
        Button {
            Task {
                do {
                    try await action()
                } catch {
                    print(
                        "Problem with Google Sign-In: \(error)"
                    )
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image("GoogleLogo")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 18, height: 18)

                Text("Sign in with Google")
                    .font(
                        .system(
                            size: 19,
                            weight: .semibold
                        )
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .buttonStyle(.plain)
        .foregroundStyle(
            colorScheme == .black
                ? Color.white
                : Color.black
        )
        .background(
            colorScheme == .black
                ? Color.black
                : Color.white
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .stroke(
                Color.black.opacity(0.08),
                lineWidth: 1
            )
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        SignInWithGoogleButton(
            colorScheme: .black,
            action: {}
        )

        SignInWithGoogleButton(
            colorScheme: .white,
            action: {}
        )
    }
    .padding()
}

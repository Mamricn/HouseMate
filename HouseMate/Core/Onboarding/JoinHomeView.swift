//
//  JoinHomeView.swift
//  HouseMate
//
//  Created by Marcin Turek on 18/08/2026.
//

import SwiftUI

@MainActor
@Observable
final class JoinHomeViewModel {

    var inviteCode = ""

    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let interactor: CoreInteractor
    private let user: UserModel
    private let onHouseholdJoined: (HouseholdModel) -> Void

    let codeLength = 6

    var hasValidInviteCode: Bool {
        inviteCode.count == codeLength
    }

    var canJoinHome: Bool {
        hasValidInviteCode && !isLoading
    }

    init(interactor: CoreInteractor, user: UserModel, onHouseholdJoined: @escaping (HouseholdModel) -> Void) {
        self.interactor = interactor
        self.user = user
        self.onHouseholdJoined = onHouseholdJoined
    }

    func updateInviteCode(_ value: String) {
        let formatted = value
            .uppercased()
            .filter { $0.isLetter || $0.isNumber }

        inviteCode = String(formatted.prefix(codeLength))
    }

    func joinHome() async {
        guard canJoinHome else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let household = try await interactor.joinHousehold(inviteCode: inviteCode, user: user)
            onHouseholdJoined(household)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }
}

struct JoinHomeView: View {

    @State var viewModel: JoinHomeViewModel
    @State private var hasAttemptedSubmit = false
    @FocusState private var isCodeFocused: Bool

    var body: some View {
        ZStack {
            background

            VStack(spacing: 30) {
                picture

                header
                    .padding(.horizontal, 24)

                inviteCodeSection
                    .padding(.horizontal, 24)

                Spacer()

                joinButton
                    .padding(.horizontal, 24)
                    .padding(.top, 70)
            }
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isCodeFocused = true
        }
        .alert("Couldn't join home", isPresented: errorBinding) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "Please try again.")
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                .blue,
                .teal,
                .blue.opacity(0.08),
                .blue.opacity(0.002),
                .black.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Join a home")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Enter the invite code shared by\none of your housemates.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var picture: some View {
        GeometryReader { geometry in
            Image("house3")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .frame(height: 360)
    }

    private var inviteCodeSection: some View {
        VStack(spacing: 14) {
            Text("Invite code")
                .font(.caption)
                .foregroundStyle(.secondary)

            ZStack {
                TextField("", text: $viewModel.inviteCode)
                    .focused($isCodeFocused)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .keyboardType(.asciiCapable)
                    .opacity(0.001)
                    .disabled(viewModel.isLoading)
                    .onChange(of: viewModel.inviteCode) { _, newValue in
                        viewModel.updateInviteCode(newValue)
                    }

                HStack(spacing: 10) {
                    ForEach(0..<viewModel.codeLength, id: \.self) { index in
                        Text(character(at: index))
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(width: 45, height: 55)
                            .glassEffect()
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isCodeFocused = true
                }
            }

            if hasAttemptedSubmit && !viewModel.hasValidInviteCode {
                FormValidationMessage(
                    message: "Enter the complete \(viewModel.codeLength)-character invite code."
                )
            }
        }
    }

    private var joinButton: some View {
        Button {
            hasAttemptedSubmit = true

            guard viewModel.hasValidInviteCode else {
                HapticFeedback.validationError()
                isCodeFocused = true
                return
            }

            Task {
                await viewModel.joinHome()
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Join home")
                        .fontWeight(.semibold)

                    Image(systemName: "arrow.right")
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .glassEffect()
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.7 : 1)
    }

    private func character(at index: Int) -> String {
        guard index < viewModel.inviteCode.count else { return "" }

        let stringIndex = viewModel.inviteCode.index(
            viewModel.inviteCode.startIndex,
            offsetBy: index
        )

        return String(viewModel.inviteCode[stringIndex])
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearError()
                }
            }
        )
    }
}

#if MOCK
#Preview {
    let container = DependencyContainer.make(environment: .mock)
    let interactor = CoreInteractor(container: container)

    NavigationStack {
        JoinHomeView(
            viewModel: JoinHomeViewModel(
                interactor: interactor,
                user: .mockNoHousehold,
                onHouseholdJoined: { _ in }
            )
        )
    }
}
#endif

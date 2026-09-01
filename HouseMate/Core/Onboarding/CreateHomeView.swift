//
//  CreateHomeView.swift
//  HouseMate
//
//  Created by Marcin Turek on 18/08/2026.
//

import SwiftUI

@MainActor
@Observable
final class CreateHomeViewModel {

    var homeName = ""

    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let interactor: CoreInteractor
    private let user: UserModel
    private let onHouseholdCreated: (HouseholdModel) -> Void

    var canCreateHome: Bool {
        !homeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    init(interactor: CoreInteractor, user: UserModel, onHouseholdCreated: @escaping (HouseholdModel) -> Void) {
        self.interactor = interactor
        self.user = user
        self.onHouseholdCreated = onHouseholdCreated
    }

    func createHome() async {
        guard canCreateHome else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let household = try await interactor.createHousehold(name: homeName, owner: user)
            onHouseholdCreated(household)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }
}

struct CreateHomeView: View {

    @State var viewModel: CreateHomeViewModel

    var body: some View {
        ZStack {
            background

            VStack(spacing: 30) {
                text
                picture
                homeName

                Spacer()

                createHomeButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 30)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Couldn't create home", isPresented: errorBinding) {
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

    private var text: some View {
        VStack(spacing: 8) {
            Text("Create your home")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Give your home a name. You can invite your housemates next.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var picture: some View {
        GeometryReader { geometry in
            Image("house4")
                .resizable()
                .scaledToFit()
                .frame(width: geometry.size.width * 0.8)
                .position(
                    x: geometry.size.width * 0.5,
                    y: geometry.size.height * 0.5
                )
        }
        .frame(height: 250)
    }

    private var homeName: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Home name")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("e.g. London Flat", text: $viewModel.homeName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .padding()
                .glassEffect()
                .disabled(viewModel.isLoading)
        }
    }

    private var createHomeButton: some View {
        Button {
            Task {
                await viewModel.createHome()
            }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Create home")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .glassEffect()
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canCreateHome)
        .opacity(viewModel.canCreateHome ? 1 : 0.5)
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
        CreateHomeView(
            viewModel: CreateHomeViewModel(
                interactor: interactor,
                user: .mockNoHousehold,
                onHouseholdCreated: { _ in }
            )
        )
    }
}
#endif

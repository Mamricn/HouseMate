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

    var hasValidHomeName: Bool {
        !homeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canCreateHome: Bool {
        hasValidHomeName && !isLoading
    }

    init(interactor: CoreInteractor, user: UserModel, onHouseholdCreated: @escaping (HouseholdModel) -> Void) {
        self.interactor = interactor
        self.user = user
        self.onHouseholdCreated = onHouseholdCreated
    }

    func createHome() async {
        guard canCreateHome else { return }

        interactor.trackEvent(Event.createHomeStart)

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let household = try await interactor.createHousehold(name: homeName, owner: user)
            interactor.trackEvent(Event.createHomeSuccess(household: household))
            onHouseholdCreated(household)
        } catch {
            interactor.trackEvent(Event.createHomeFail(error: error))
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }

    enum Event: LoggableEvent {
        case createHomeStart
        case createHomeSuccess(household: HouseholdModel)
        case createHomeFail(error: Error)

        var eventName: String {
            switch self {
            case .createHomeStart: "CreateHomeView_CreateHome_Start"
            case .createHomeSuccess: "CreateHomeView_CreateHome_Success"
            case .createHomeFail: "CreateHomeView_CreateHome_Fail"
            }
        }

        var parameters: [String: Any]? {
            switch self {
            case .createHomeSuccess(let household): household.eventParameters
            case .createHomeFail(let error): error.eventParameters
            default: nil
            }
        }

        var type: LogType {
            if case .createHomeFail = self { return .severe }
            return .analytic
        }
    }
}

struct CreateHomeView: View {

    @State var viewModel: CreateHomeViewModel
    @State private var hasAttemptedSubmit = false
    @FocusState private var isHomeNameFocused: Bool

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
        .screenAppearAnalytics(name: "CreateHomeView")
        .alert("Couldn't create home", isPresented: errorBinding) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "Please try again.")
        }
    }

    private var background: some View {
        OnboardingBackground()
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
                .focused($isHomeNameFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .padding()
                .glassEffect()
                .disabled(viewModel.isLoading)

            if hasAttemptedSubmit && !viewModel.hasValidHomeName {
                FormValidationMessage(message: "Enter a name for your home.")
            }
        }
    }

    private var createHomeButton: some View {
        Button {
            hasAttemptedSubmit = true

            guard viewModel.hasValidHomeName else {
                HapticFeedback.validationError()
                isHomeNameFocused = true
                return
            }

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
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.7 : 1)
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

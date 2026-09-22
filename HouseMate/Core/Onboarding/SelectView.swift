//
//  SelectView.swift
//  HouseMate
//
//  Created by Marcin Turek on 17/08/2026.
//

import SwiftUI

enum OnboardingDestination: Hashable {
    case createHome
    case joinHome
}

@MainActor
@Observable
final class SelectViewModel {

    private let interactor: CoreInteractor
    private let user: UserModel
    private let onHouseholdCompleted: (HouseholdModel) -> Void

    init(interactor: CoreInteractor, user: UserModel, onHouseholdCompleted: @escaping (HouseholdModel) -> Void) {
        self.interactor = interactor
        self.user = user
        self.onHouseholdCompleted = onHouseholdCompleted
    }

    func makeCreateHomeViewModel() -> CreateHomeViewModel {
        CreateHomeViewModel(
            interactor: interactor,
            user: user,
            onHouseholdCreated: onHouseholdCompleted
        )
    }

    func makeJoinHomeViewModel(inviteCode: String = "") -> JoinHomeViewModel {
        JoinHomeViewModel(
            interactor: interactor,
            user: user,
            inviteCode: inviteCode,
            onHouseholdJoined: onHouseholdCompleted
        )
    }

}

struct SelectView: View {

    @State var viewModel: SelectViewModel
    let pendingDeepLink: AppDeepLink?
    var onDeepLinkHandled: (AppDeepLink) -> Void

    @State private var path: [OnboardingDestination]
    @State private var pendingInviteCode: String

    init(
        viewModel: SelectViewModel,
        pendingDeepLink: AppDeepLink? = nil,
        onDeepLinkHandled: @escaping (AppDeepLink) -> Void = { _ in }
    ) {
        self.viewModel = viewModel
        self.pendingDeepLink = pendingDeepLink
        self.onDeepLinkHandled = onDeepLinkHandled

        if case let .joinHousehold(inviteCode) = pendingDeepLink {
            _path = State(initialValue: [.joinHome])
            _pendingInviteCode = State(initialValue: inviteCode)
        } else {
            _path = State(initialValue: [])
            _pendingInviteCode = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                background

                VStack(spacing: 30) {
                    picture
                    text
                    buttons
                }
                .padding(.horizontal, 10)
            }
            .navigationBarBackButtonHidden()
            .navigationDestination(for: OnboardingDestination.self) { destination in
                destinationView(destination)
            }
        }
        .onAppear {
            if case .joinHousehold = pendingDeepLink,
               let pendingDeepLink {
                onDeepLinkHandled(pendingDeepLink)
            }
        }
        .screenAppearAnalytics(name: "SelectView")
    }

    private var background: some View {
        OnboardingBackground()
    }

    private var picture: some View {
        GeometryReader { geometry in
            Image("house2")
                .resizable()
                .scaledToFit()
                .frame(width: geometry.size.width * 0.8)
                .position(
                    x: geometry.size.width * 0.5,
                    y: geometry.size.height * 0.5
                )
        }
        .frame(height: 300)
    }

    private var text: some View {
        VStack(spacing: 8) {
            Text("Set up your home")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Create a new home or join one that already exists.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var buttons: some View {
        VStack(spacing: 16) {
            onboardingButton(
                title: "Create a new home",
                subtitle: "Set up a home and invite others",
                systemImage: "house"
            ) {
                path.append(.createHome)
            }

            onboardingButton(
                title: "Join a home",
                subtitle: "Join using an invite code",
                systemImage: "person.2.fill"
            ) {
                path.append(.joinHome)
            }
        }
        .padding(.horizontal, 24)
    }

    private func onboardingButton(title: String, subtitle: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(15)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
    }

    @ViewBuilder
    private func destinationView(_ destination: OnboardingDestination) -> some View {
        switch destination {
        case .createHome:
            CreateHomeView(viewModel: viewModel.makeCreateHomeViewModel())

        case .joinHome:
            JoinHomeView(
                viewModel: viewModel.makeJoinHomeViewModel(
                    inviteCode: pendingInviteCode
                )
            )
        }
    }
}

#if MOCK
#Preview {
    let container = DependencyContainer.make(environment: .mock)
    let interactor = CoreInteractor(container: container)

    SelectView(
        viewModel: SelectViewModel(
            interactor: interactor,
            user: .mockNoHousehold,
            onHouseholdCompleted: { _ in }
        )
    )
}
#endif

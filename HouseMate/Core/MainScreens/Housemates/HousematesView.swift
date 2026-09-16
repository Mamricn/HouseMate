//
//  HousematesView.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//


import SwiftUI

@Observable
@MainActor
final class HousematesViewModel {

    private let interactor: CoreInteractor
    let actionState = AsyncActionState()

    var currentUser: UserModel

    var users: [UserModel]

    var members: [HouseholdMemberModel]

    let householdOwnerUserID: String

    var isCurrentUserOwner: Bool {
        householdOwnerUserID == currentUser.id
    }

    var household: HouseholdModel? {
        interactor.currentHousehold
    }

    var posts: [BoardPostModel] {
        interactor.boardPosts
    }

    var isLoadingMorePosts: Bool {
        interactor.isLoadingMoreBoardPosts
    }

    var canLoadMorePosts: Bool {
        interactor.canLoadMoreBoardPosts
    }

    init(currentUser: UserModel, users: [UserModel], members: [HouseholdMemberModel], householdOwnerUserID: String, interactor: CoreInteractor) {
        self.currentUser = currentUser
        self.users = users
        self.members = members
        self.householdOwnerUserID = householdOwnerUserID
        self.interactor = interactor
    }

    convenience init() {
        let container = DependencyContainer.make(environment: .mock)

        self.init(
            currentUser: UserModel.mockList[0],
            users: UserModel.mockList,
            members: HouseholdMemberModel.mockList,
            householdOwnerUserID: HouseholdModel.mock.ownerUserId,
            interactor: CoreInteractor(container: container)
        )
    }

    // MARK: - Board Actions

    func addPost(text: String) async -> Bool {
        guard let householdId = currentUser.householdId else {
            return false
        }

        let newPost = BoardPostModel(
            postId: UUID().uuidString,
            householdId: householdId,
            createdAt: .now,
            createdByUserId: currentUser.id,
            text: text,
            imageUrl: nil
        )

        return await actionState.perform {
            try await interactor.createBoardPost(newPost)
        }
    }

    func deletePost(_ post: BoardPostModel) async -> Bool {
        await actionState.perform {
            try await interactor.deleteBoardPost(
                post,
                currentUserID: currentUser.id
            )
        }
    }

    func fetchInitialPosts() async {
        guard let householdID = currentUser.householdId else {
            return
        }

        await actionState.capture {
            try await interactor.fetchInitialBoardPosts(householdID: householdID)
        }
    }

    func loadMorePosts() {
        Task {
            await actionState.capture {
                try await interactor.loadMoreBoardPosts()
            }
        }
    }

    func refreshData() async {
        guard let householdID = currentUser.householdId else {
            return
        }

        await actionState.capture {
            try await interactor.fetchInitialBoardPosts(householdID: householdID)
        }
    }
}

// MARK: - Sheet

private enum HousematesSheet: String, Identifiable {
    case housemate
    case post

    var id: String {
        rawValue
    }
}

struct HousematesView: View {

    let viewModel: HousematesViewModel

    @State private var activeSheet: HousematesSheet?
    @State private var toast: AppToast?

    var body: some View {
        ZStack {
            backgroundGradient
            content
            toastOverlay
        }
        .sheet(item: $activeSheet) { sheet in
            sheetContent(for: sheet)
        }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            LazyVStack(
                alignment: .leading,
                spacing: 20
            ) {
                membersCard
                boardCard
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 35)
        }
        .houseMatePullToRefresh {
            await viewModel.refreshData()

            if let errorMessage = viewModel.actionState.errorMessage {
                showToast(
                    message: errorMessage,
                    systemImage: "exclamationmark.triangle.fill",
                    color: .red
                )
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Members

    private var membersCard: some View {
        HouseholdMembersCardView(
            members: viewModel.members,
            showsAddButton: true,
            onAdd: {
                activeSheet = .housemate
            }
        )
        .housematesCardShadow()
    }

    // MARK: - Board

    private var boardCard: some View {
        HouseholdBoardCardView(
            posts: viewModel.posts,
            users: viewModel.users,
            currentUserId: viewModel.currentUser.id,
            showsAddButton: true,
            onAdd: {
                activeSheet = .post
            },
            onDelete: { post in
                performAction(
                    successMessage: "Post deleted",
                    systemImage: "trash.fill",
                    color: .red,
                    operation: {
                        await viewModel.deletePost(post)
                    }
                )
            },
            canLoadMore: viewModel.canLoadMorePosts,
            isLoadingMore: viewModel.isLoadingMorePosts,
            onLoadMore: {
                viewModel.loadMorePosts()
            }
        )
        .housematesCardShadow()
    }

    // MARK: - Sheets

    @ViewBuilder
    private func sheetContent(
        for sheet: HousematesSheet
    ) -> some View {
        switch sheet {
        case .housemate:
            housemateSheet

        case .post:
            postSheet
        }
    }

    private var housemateSheet: some View {
        Group {
            if let household = viewModel.household {
                AddHousemateView(household: household)
            } else {
                ContentUnavailableView(
                    "Household unavailable",
                    systemImage: "house.slash",
                    description: Text("Close this screen and try again.")
                )
            }
        }
        .presentationDetents([.height(520)])
        .presentationDragIndicator(.visible)
    }

    private var postSheet: some View {
        AddBoardPostView { text in
            performAction(
                successMessage: "Post added",
                systemImage: "text.bubble.fill",
                color: .green,
                operation: {
                    await viewModel.addPost(text: text)
                }
            )
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Toast

    @ViewBuilder
    private var toastOverlay: some View {
        if let toast {
            VStack {
                AppToastView(toast: toast)
                    .transition(
                        .move(edge: .top)
                        .combined(with: .opacity)
                    )

                Spacer()
            }
            .padding(.top, 12)
            .zIndex(100)
            .allowsHitTesting(false)
        }
    }

    private func showToast(
        message: String,
        systemImage: String,
        color: Color
    ) {
        let newToast = AppToast(
            message: message,
            systemImage: systemImage,
            color: color
        )

        withAnimation(.spring(response: 0.4)) {
            toast = newToast
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 2.5
        ) {
            guard toast?.id == newToast.id else {
                return
            }

            withAnimation(.easeInOut(duration: 0.25)) {
                toast = nil
            }
        }
    }

    private func performAction(successMessage: String, systemImage: String, color: Color, operation: @escaping @MainActor () async -> Bool) {
        Task {
            let succeeded = await operation()

            showToast(
                message: succeeded
                    ? successMessage
                    : viewModel.actionState.errorMessage ?? "Something went wrong. Please try again.",
                systemImage: succeeded ? systemImage : "exclamationmark.triangle.fill",
                color: succeeded ? color : .red
            )
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Color(.secondarySystemBackground)

            LinearGradient(
                colors: [
                    Color.purple.opacity(0.16),
                    Color.blue.opacity(0.12),
                    Color.cyan.opacity(0.07),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.purple.opacity(0.13))
                .frame(width: 280, height: 280)
                .blur(radius: 75)
                .offset(x: 150, y: -300)

            Circle()
                .fill(Color.blue.opacity(0.10))
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .offset(x: -160, y: 320)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Card Shadow

private extension View {

    func housematesCardShadow() -> some View {
        shadow(
            color: Color.black.opacity(0.07),
            radius: 14,
            x: 0,
            y: 7
        )
    }
}

// MARK: - Preview

#Preview {
    HousematesView(
        viewModel: HousematesViewModel()
    )
}

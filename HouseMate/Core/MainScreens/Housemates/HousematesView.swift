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

        interactor.trackEvent(Event.addPostStart(post: newPost))
        do {
            try await actionState.run { try await interactor.createBoardPost(newPost) }
            interactor.trackEvent(Event.addPostSuccess(post: newPost)); return true
        } catch { interactor.trackEvent(Event.addPostFail(error: error, post: newPost)); return false }
    }

    func deletePost(_ post: BoardPostModel) async -> Bool {
        interactor.trackEvent(Event.deletePostStart(post: post))
        do {
            try await actionState.run { try await interactor.deleteBoardPost(post, currentUserID: currentUser.id) }
            interactor.trackEvent(Event.deletePostSuccess(post: post)); return true
        } catch { interactor.trackEvent(Event.deletePostFail(error: error, post: post)); return false }
    }

    func fetchInitialPosts() async {
        guard let householdID = currentUser.householdId else {
            return
        }

        interactor.trackEvent(Event.fetchInitialPostsStart)
        do {
            try await actionState.run { try await interactor.fetchInitialBoardPosts(householdID: householdID) }
            interactor.trackEvent(Event.fetchInitialPostsSuccess)
        } catch { interactor.trackEvent(Event.fetchInitialPostsFail(error: error)) }
    }

    func loadMorePosts() {
        Task {
            interactor.trackEvent(Event.loadMorePostsStart)
            do {
                try await actionState.run { try await interactor.loadMoreBoardPosts() }
                interactor.trackEvent(Event.loadMorePostsSuccess)
            } catch { interactor.trackEvent(Event.loadMorePostsFail(error: error)) }
        }
    }

    func refreshData() async {
        guard let householdID = currentUser.householdId else {
            return
        }

        interactor.trackEvent(Event.refreshDataStart)
        do {
            try await actionState.run { try await interactor.fetchInitialBoardPosts(householdID: householdID) }
            interactor.trackEvent(Event.refreshDataSuccess)
        } catch { interactor.trackEvent(Event.refreshDataFail(error: error)) }
    }

    enum Event: LoggableEvent {
        case addPostStart(post: BoardPostModel)
        case addPostSuccess(post: BoardPostModel)
        case addPostFail(error: Error, post: BoardPostModel)
        case deletePostStart(post: BoardPostModel)
        case deletePostSuccess(post: BoardPostModel)
        case deletePostFail(error: Error, post: BoardPostModel)
        case fetchInitialPostsStart
        case fetchInitialPostsSuccess
        case fetchInitialPostsFail(error: Error)
        case loadMorePostsStart
        case loadMorePostsSuccess
        case loadMorePostsFail(error: Error)
        case refreshDataStart
        case refreshDataSuccess
        case refreshDataFail(error: Error)

        var eventName: String {
            switch self {
            case .addPostStart: "HousematesView_AddPost_Start"
            case .addPostSuccess: "HousematesView_AddPost_Success"
            case .addPostFail: "HousematesView_AddPost_Fail"
            case .deletePostStart: "HousematesView_DeletePost_Start"
            case .deletePostSuccess: "HousematesView_DeletePost_Success"
            case .deletePostFail: "HousematesView_DeletePost_Fail"
            case .fetchInitialPostsStart: "HousematesView_FetchInitialPosts_Start"
            case .fetchInitialPostsSuccess: "HousematesView_FetchInitialPosts_Success"
            case .fetchInitialPostsFail: "HousematesView_FetchInitialPosts_Fail"
            case .loadMorePostsStart: "HousematesView_LoadMorePosts_Start"
            case .loadMorePostsSuccess: "HousematesView_LoadMorePosts_Success"
            case .loadMorePostsFail: "HousematesView_LoadMorePosts_Fail"
            case .refreshDataStart: "HousematesView_RefreshData_Start"
            case .refreshDataSuccess: "HousematesView_RefreshData_Success"
            case .refreshDataFail: "HousematesView_RefreshData_Fail"
            }
        }

        var parameters: [String: Any]? {
            switch self {
            case .addPostStart(let post), .addPostSuccess(let post),
                 .deletePostStart(let post), .deletePostSuccess(let post):
                post.eventParameters
            case .addPostFail(let error, let post),
                 .deletePostFail(let error, let post):
                post.eventParameters.merging(error.eventParameters) { current, _ in current }
            case .fetchInitialPostsFail(let error), .loadMorePostsFail(let error),
                 .refreshDataFail(let error):
                error.eventParameters
            default:
                nil
            }
        }

        var type: LogType {
            switch self {
            case .addPostFail, .deletePostFail, .fetchInitialPostsFail,
                 .loadMorePostsFail, .refreshDataFail:
                .severe
            default:
                .analytic
            }
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
        .screenAppearAnalytics(name: "HousematesView")
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

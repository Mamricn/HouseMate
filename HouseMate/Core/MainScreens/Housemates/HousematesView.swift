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

    var posts: [BoardPostModel] {
        interactor.boardPosts
    }

    var isLoadingMorePosts: Bool {
        interactor.isLoadingMoreBoardPosts
    }

    var canLoadMorePosts: Bool {
        interactor.canLoadMoreBoardPosts
    }

    var polls: [PollModel] {
        interactor.polls
    }

    var reminders: [HouseReminderModel] {
        interactor.houseReminders
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
            householdOwnerUserID: HouseholdModel.mock.createdByUserId,
            interactor: CoreInteractor(container: container)
        )
    }

    // MARK: - Housemate Actions

    func addHousemate(
        name: String,
        email: String
    ) {
        guard let householdId = currentUser.householdId else {
            return
        }

        let userId = UUID().uuidString

        let newUser = UserModel(
            userId: userId,
            createdAt: .now,
            email: email,
            name: name,
            householdId: householdId
        )

        let newMember = HouseholdMemberModel(
            memberId: UUID().uuidString,
            householdId: householdId,
            userId: userId,
            joinedAt: .now,
            displayName: name
        )

        users.append(newUser)
        members.append(newMember)
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

    // MARK: - Poll Actions

    func addPoll(
        question: String,
        options: [String],
        expiresAt: Date?
    ) async -> Bool {
        guard let householdId = currentUser.householdId else {
            return false
        }

        let pollOptions = options.map { option in
            PollOptionModel(
                optionId: UUID().uuidString,
                text: option
            )
        }

        let newPoll = PollModel(
            pollId: UUID().uuidString,
            householdId: householdId,
            createdAt: .now,
            createdByUserId: currentUser.id,
            question: question,
            options: pollOptions,
            votesByUserId: [:],
            status: .active,
            expiresAt: expiresAt
        )

        return await actionState.perform {
            try await interactor.createPoll(newPoll)
        }
    }

    func vote(
        in poll: PollModel,
        for option: PollOptionModel
    ) async -> Bool {
        await actionState.perform {
            try await interactor.vote(
                in: poll,
                option: option,
                userID: currentUser.id
            )
        }
    }

    func closePoll(_ poll: PollModel) async -> Bool {
        await actionState.perform {
            try await interactor.closePoll(
                poll,
                currentUserID: currentUser.id
            )
        }
    }

    func deletePoll(_ poll: PollModel) async -> Bool {
        await actionState.perform {
            try await interactor.deletePoll(
                poll,
                currentUserID: currentUser.id
            )
        }
    }

    func fetchPolls() async {
        guard let householdID = currentUser.householdId else {
            return
        }

        await actionState.capture {
            try await interactor.fetchPolls(householdID: householdID)
        }
    }

    // MARK: - Reminder Actions

    func addReminder(
        title: String,
        details: String?,
        firstOccurrenceDate: Date,
        recurrence: HouseReminderRecurrence,
        category: HouseReminderCategory,
        reminderAdvance: HouseReminderAdvance
    ) async -> Bool {
        guard let householdId = currentUser.householdId else {
            return false
        }

        let newReminder = HouseReminderModel(
            reminderId: UUID().uuidString,
            householdId: householdId,
            createdAt: .now,
            createdByUserId: currentUser.id,
            title: title,
            details: details,
            firstOccurrenceDate: firstOccurrenceDate,
            recurrence: recurrence,
            category: category,
            reminderAdvance: reminderAdvance
        )

        return await actionState.perform {
            try await interactor.createHouseReminder(newReminder)
        }
    }

    func deleteReminder(
        _ reminder: HouseReminderModel
    ) async -> Bool {
        await actionState.perform {
            try await interactor.deleteHouseReminder(
                reminder,
                currentUserID: currentUser.id,
                ownerUserID: householdOwnerUserID
            )
        }
    }

    func fetchReminders() async {
        guard let householdID = currentUser.householdId else {
            return
        }

        await actionState.capture {
            try await interactor.fetchHouseReminders(householdID: householdID)
        }
    }

    func refreshData() async {
        guard let householdID = currentUser.householdId else {
            return
        }

        await actionState.capture {
            try await interactor.fetchInitialBoardPosts(householdID: householdID)
            try await interactor.fetchPolls(householdID: householdID)
            try await interactor.fetchHouseReminders(householdID: householdID)
        }
    }
}

// MARK: - Sheet

private enum HousematesSheet: String, Identifiable {
    case housemate
    case post
    case poll
    case reminder

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
                header
                membersCard
                boardCard
                pollsCard
                remindersCard
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 35)
        }
        .refreshable {
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

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Housemates")
                .font(
                    .system(
                        size: 30,
                        weight: .bold,
                        design: .rounded
                    )
                )

            Text("Connect with everyone at home")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
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

    // MARK: - Polls

    private var pollsCard: some View {
        HouseholdPollsCardView(
            polls: viewModel.polls,
            currentUserId: viewModel.currentUser.id,
            members: viewModel.members,
            showsAddButton: true,
            onAdd: {
                activeSheet = .poll
            },
            onVote: { poll, option in
                performAction(
                    successMessage: "Vote submitted",
                    systemImage: "checkmark.circle.fill",
                    color: .green,
                    operation: {
                        await viewModel.vote(
                        in: poll,
                        for: option
                    )
                    }
                )
            },
            onClose: { poll in
                performAction(
                    successMessage: "Poll closed",
                    systemImage: "checkmark.circle",
                    color: .orange,
                    operation: {
                        await viewModel.closePoll(poll)
                    }
                )
            },
            onDelete: { poll in
                performAction(
                    successMessage: "Poll deleted",
                    systemImage: "trash.fill",
                    color: .red,
                    operation: {
                        await viewModel.deletePoll(poll)
                    }
                )
            }
        )
        .housematesCardShadow()
    }

    // MARK: - Reminders

    private var remindersCard: some View {
        HouseRemindersCardView(
            reminders: viewModel.reminders,
            currentUserId: viewModel.currentUser.id,
            householdOwnerUserId: viewModel.householdOwnerUserID,
            showsAddButton: true,
            onAdd: {
                activeSheet = .reminder
            },
            onDelete: { reminder in
                performAction(
                    successMessage: "\(reminder.title) deleted",
                    systemImage: "trash.fill",
                    color: .red,
                    operation: {
                        await viewModel.deleteReminder(reminder)
                    }
                )
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

        case .poll:
            pollSheet

        case .reminder:
            reminderSheet
        }
    }

    private var housemateSheet: some View {
        AddHousemateView { name, email in
            withAnimation {
                viewModel.addHousemate(
                    name: name,
                    email: email
                )
            }

            showToast(
                message: "\(name) invited",
                systemImage: "person.badge.plus",
                color: .green
            )
        }
        .presentationDetents([.medium])
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

    private var pollSheet: some View {
        AddPollView {
            question,
            options,
            expiresAt in

            performAction(
                successMessage: "Poll created",
                systemImage: "chart.bar.doc.horizontal",
                color: .green,
                operation: {
                    await viewModel.addPoll(
                    question: question,
                    options: options,
                    expiresAt: expiresAt
                )
                }
            )
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var reminderSheet: some View {
        AddHouseReminderView {
            title,
            details,
            firstOccurrenceDate,
            recurrence,
            category,
            reminderAdvance in

            performAction(
                successMessage: "\(title) added",
                systemImage: "bell.badge.fill",
                color: .green,
                operation: {
                    await viewModel.addReminder(
                    title: title,
                    details: details,
                    firstOccurrenceDate: firstOccurrenceDate,
                    recurrence: recurrence,
                    category: category,
                    reminderAdvance: reminderAdvance
                )
                }
            )
        }
        .presentationDetents([.large])
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
            Color(.systemBackground)

            LinearGradient(
                colors: [
                    Color.purple.opacity(0.16),
                    Color.blue.opacity(0.12),
                    Color.cyan.opacity(0.07),
                    Color(.systemBackground)
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

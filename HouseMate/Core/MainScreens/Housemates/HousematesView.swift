//
//  HousematesView.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//


import SwiftUI

@Observable
final class HousematesViewModel {

    var currentUser: UserModel =
        UserModel.mockList[0]

    var users: [UserModel] =
        UserModel.mockList

    var members: [HouseholdMemberModel] =
        HouseholdMemberModel.mockList

    var posts: [BoardPostModel] =
        BoardPostModel.mockList

    var polls: [PollModel] =
        PollModel.mockList

    var reminders: [HouseReminderModel] =
        HouseReminderModel.mockList

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

    func addPost(text: String) {
        guard let householdId = currentUser.householdId else {
            return
        }

        let newPost = BoardPostModel(
            postId: UUID().uuidString,
            householdId: householdId,
            createdAt: .now,
            createdByUserId: currentUser.id,
            text: text,
            imageUrl: nil
        )

        posts.append(newPost)
    }

    func deletePost(_ post: BoardPostModel) {
        posts.removeAll {
            $0.id == post.id
        }
    }

    // MARK: - Poll Actions

    func addPoll(
        question: String,
        options: [String],
        expiresAt: Date?
    ) {
        guard let householdId = currentUser.householdId else {
            return
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

        polls.append(newPoll)
    }

    func vote(
        in poll: PollModel,
        for option: PollOptionModel
    ) {
        guard let index = polls.firstIndex(where: {
            $0.id == poll.id
        }) else {
            return
        }

        polls[index]
            .votesByUserId[currentUser.id] = option.id
    }

    func closePoll(_ poll: PollModel) {
        guard
            poll.createdByUserId == currentUser.id,
            let index = polls.firstIndex(where: {
                $0.id == poll.id
            })
        else {
            return
        }

        polls[index].status = .closed
    }

    func deletePoll(_ poll: PollModel) {
        guard poll.createdByUserId == currentUser.id else {
            return
        }

        polls.removeAll {
            $0.id == poll.id
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
    ) {
        guard let householdId = currentUser.householdId else {
            return
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

        reminders.append(newReminder)
    }

    func deleteReminder(
        _ reminder: HouseReminderModel
    ) {
        reminders.removeAll {
            $0.id == reminder.id
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
                withAnimation {
                    viewModel.deletePost(post)
                }

                showToast(
                    message: "Post deleted",
                    systemImage: "trash.fill",
                    color: .red
                )
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
                withAnimation {
                    viewModel.vote(
                        in: poll,
                        for: option
                    )
                }

                showToast(
                    message: "Vote submitted",
                    systemImage: "checkmark.circle.fill",
                    color: .green
                )
            },
            onClose: { poll in
                withAnimation {
                    viewModel.closePoll(poll)
                }

                showToast(
                    message: "Poll closed",
                    systemImage: "checkmark.circle",
                    color: .orange
                )
            },
            onDelete: { poll in
                withAnimation {
                    viewModel.deletePoll(poll)
                }

                showToast(
                    message: "Poll deleted",
                    systemImage: "trash.fill",
                    color: .red
                )
            }
        )
        .housematesCardShadow()
    }

    // MARK: - Reminders

    private var remindersCard: some View {
        HouseRemindersCardView(
            reminders: viewModel.reminders,
            showsAddButton: true,
            onAdd: {
                activeSheet = .reminder
            },
            onDelete: { reminder in
                withAnimation {
                    viewModel.deleteReminder(reminder)
                }

                showToast(
                    message: "\(reminder.title) deleted",
                    systemImage: "trash.fill",
                    color: .red
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
            withAnimation {
                viewModel.addPost(text: text)
            }

            showToast(
                message: "Post added",
                systemImage: "text.bubble.fill",
                color: .green
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

            withAnimation {
                viewModel.addPoll(
                    question: question,
                    options: options,
                    expiresAt: expiresAt
                )
            }

            showToast(
                message: "Poll created",
                systemImage: "chart.bar.doc.horizontal",
                color: .green
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

            withAnimation {
                viewModel.addReminder(
                    title: title,
                    details: details,
                    firstOccurrenceDate: firstOccurrenceDate,
                    recurrence: recurrence,
                    category: category,
                    reminderAdvance: reminderAdvance
                )
            }

            showToast(
                message: "\(title) added",
                systemImage: "bell.badge.fill",
                color: .green
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

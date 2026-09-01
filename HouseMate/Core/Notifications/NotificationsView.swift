//
//  NotificationsView.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//


import SwiftUI

@Observable
@MainActor
final class NotificationsViewModel {

    let currentUserId: String
    let actionState = AsyncActionState()

    private let interactor: CoreInteractor

    init(currentUserId: String, interactor: CoreInteractor) {
        self.currentUserId = currentUserId
        self.interactor = interactor
    }

    var notifications: [NotificationModel] {
        interactor.notifications
    }

    var userNotifications: [NotificationModel] {
        notifications
            .filter {
                $0.recipientUserId == currentUserId
            }
            .sorted {
                ($0.createdAt ?? .distantPast)
                    > ($1.createdAt ?? .distantPast)
            }
    }

    var unreadCount: Int {
        userNotifications.filter {
            !$0.isRead
        }.count
    }

    func fetchNotifications() async {
        await actionState.capture {
            try await interactor.fetchNotifications(userID: currentUserId)
        }
    }

    func markAsRead(_ notification: NotificationModel) async -> Bool {
        await actionState.perform {
            try await interactor.markNotificationAsRead(notification, userID: currentUserId)
        }
    }

    func markAllAsRead() async -> Bool {
        await actionState.perform {
            try await interactor.markAllNotificationsAsRead(userID: currentUserId)
        }
    }

    func deleteNotification(_ notification: NotificationModel) async -> Bool {
        await actionState.perform {
            try await interactor.deleteNotification(notification, userID: currentUserId)
        }
    }
}

struct NotificationsView: View {

    @Environment(\.dismiss) private var dismiss

    @State var viewModel: NotificationsViewModel

    var onOpenNotification:
        (NotificationModel) -> Void = { _ in }

    @State private var referenceDate = Date.now

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.userNotifications.isEmpty {
                    emptyState
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                leadingToolbar
                trailingToolbar
            }
        }
        .onAppear {
            referenceDate = .now
        }
    }

    // MARK: - List

    private var notificationsList: some View {
        List {
            if !todayNotifications.isEmpty {
                Section("Today") {
                    notificationRows(
                        todayNotifications
                    )
                }
            }

            if !earlierNotifications.isEmpty {
                Section("Earlier") {
                    notificationRows(
                        earlierNotifications
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private func notificationRows(
        _ notifications: [NotificationModel]
    ) -> some View {
        ForEach(notifications) { notification in
            NotificationRowView(
                notification: notification,
                referenceDate: referenceDate
            )
            .onTapGesture {
                openNotification(notification)
            }
            .swipeActions(
                edge: .leading,
                allowsFullSwipe: false
            ) {
                Button(role: .destructive) {
                    Task {
                        _ = await viewModel.deleteNotification(notification)
                    }
                } label: {
                    Label(
                        "Delete",
                        systemImage: "trash.fill"
                    )
                }
            }
            .roundedSwipeActions()
        }
    }

    // MARK: - Sections

    private var todayNotifications:
        [NotificationModel] {
        viewModel.userNotifications.filter {
            guard let createdAt = $0.createdAt else {
                return false
            }

            return Calendar.autoupdatingCurrent
                .isDateInToday(createdAt)
        }
    }

    private var earlierNotifications:
        [NotificationModel] {
        viewModel.userNotifications.filter {
            guard let createdAt = $0.createdAt else {
                return true
            }

            return !Calendar.autoupdatingCurrent
                .isDateInToday(createdAt)
        }
    }

    // MARK: - Actions

    private func openNotification(
        _ notification: NotificationModel
    ) {
        Task {
            _ = await viewModel.markAsRead(notification)
        }

        onOpenNotification(notification)
    }

    // MARK: - Toolbar

    private var leadingToolbar: some ToolbarContent {
        ToolbarItem(
            placement: .cancellationAction
        ) {
            Button("Done") {
                dismiss()
            }
        }
    }

    @ToolbarContentBuilder
    private var trailingToolbar: some ToolbarContent {
        if viewModel.unreadCount > 0 {
            ToolbarItem(
                placement: .confirmationAction
            ) {
                Button("Read All") {
                    Task {
                        _ = await viewModel.markAllAsRead()
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "No Notifications",
            systemImage: "bell.slash",
            description: Text(
                "You’re all caught up."
            )
        )
    }
}

// MARK: - Preview

#Preview {
    let container = DependencyContainer.make(environment: .mock)
    let interactor = CoreInteractor(container: container)
    let viewModel = NotificationsViewModel(currentUserId: "1", interactor: interactor)

    NotificationsView(viewModel: viewModel)
        .task {
            await viewModel.fetchNotifications()
        }
}

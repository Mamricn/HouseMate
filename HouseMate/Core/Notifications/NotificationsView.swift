//
//  NotificationsView.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//


import SwiftUI

@Observable
final class NotificationsViewModel {

    var currentUserId: String
    var notifications: [NotificationModel]

    init(
        currentUserId: String = "1",
        notifications: [NotificationModel] =
            NotificationModel.mockList
    ) {
        self.currentUserId = currentUserId
        self.notifications = notifications
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

    func markAsRead(
        _ notification: NotificationModel
    ) {
        guard let index = notifications.firstIndex(where: {
            $0.id == notification.id
        }) else {
            return
        }

        notifications[index].isRead = true
    }

    func markAllAsRead() {
        for index in notifications.indices
        where notifications[index].recipientUserId
            == currentUserId {
            notifications[index].isRead = true
        }
    }

    func deleteNotification(
        _ notification: NotificationModel
    ) {
        notifications.removeAll {
            $0.id == notification.id
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
                    withAnimation {
                        viewModel.deleteNotification(
                            notification
                        )
                    }
                } label: {
                    Label(
                        "Delete",
                        systemImage: "trash.fill"
                    )
                }
            }
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
        withAnimation {
            viewModel.markAsRead(notification)
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
                    withAnimation {
                        viewModel.markAllAsRead()
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
    NotificationsView(
        viewModel: NotificationsViewModel()
    )
}

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
        interactor.trackEvent(Event.fetchNotificationsStart)
        do {
            try await actionState.run { try await interactor.fetchNotifications(userID: currentUserId) }
            interactor.trackEvent(Event.fetchNotificationsSuccess)
        } catch { interactor.trackEvent(Event.fetchNotificationsFail(error: error)) }
    }

    func markAsRead(_ notification: NotificationModel) async -> Bool {
        interactor.trackEvent(Event.markAsReadStart(notification: notification))
        do {
            try await actionState.run { try await interactor.markNotificationAsRead(notification, userID: currentUserId) }
            interactor.trackEvent(Event.markAsReadSuccess(notification: notification)); return true
        } catch { interactor.trackEvent(Event.markAsReadFail(error: error, notification: notification)); return false }
    }

    func markAllAsRead() async -> Bool {
        interactor.trackEvent(Event.markAllAsReadStart)
        do {
            try await actionState.run { try await interactor.markAllNotificationsAsRead(userID: currentUserId) }
            interactor.trackEvent(Event.markAllAsReadSuccess); return true
        } catch { interactor.trackEvent(Event.markAllAsReadFail(error: error)); return false }
    }

    func deleteNotification(_ notification: NotificationModel) async -> Bool {
        interactor.trackEvent(Event.deleteNotificationStart(notification: notification))
        do {
            try await actionState.run { try await interactor.deleteNotification(notification, userID: currentUserId) }
            interactor.trackEvent(Event.deleteNotificationSuccess(notification: notification)); return true
        } catch { interactor.trackEvent(Event.deleteNotificationFail(error: error, notification: notification)); return false }
    }

    enum Event: LoggableEvent {
        case fetchNotificationsStart
        case fetchNotificationsSuccess
        case fetchNotificationsFail(error: Error)
        case markAsReadStart(notification: NotificationModel)
        case markAsReadSuccess(notification: NotificationModel)
        case markAsReadFail(error: Error, notification: NotificationModel)
        case markAllAsReadStart
        case markAllAsReadSuccess
        case markAllAsReadFail(error: Error)
        case deleteNotificationStart(notification: NotificationModel)
        case deleteNotificationSuccess(notification: NotificationModel)
        case deleteNotificationFail(error: Error, notification: NotificationModel)

        var eventName: String {
            switch self {
            case .fetchNotificationsStart: "NotificationsView_FetchNotifications_Start"
            case .fetchNotificationsSuccess: "NotificationsView_FetchNotifications_Success"
            case .fetchNotificationsFail: "NotificationsView_FetchNotifications_Fail"
            case .markAsReadStart: "NotificationsView_MarkAsRead_Start"
            case .markAsReadSuccess: "NotificationsView_MarkAsRead_Success"
            case .markAsReadFail: "NotificationsView_MarkAsRead_Fail"
            case .markAllAsReadStart: "NotificationsView_MarkAllAsRead_Start"
            case .markAllAsReadSuccess: "NotificationsView_MarkAllAsRead_Success"
            case .markAllAsReadFail: "NotificationsView_MarkAllAsRead_Fail"
            case .deleteNotificationStart: "NotificationsView_DeleteNotification_Start"
            case .deleteNotificationSuccess: "NotificationsView_DeleteNotification_Success"
            case .deleteNotificationFail: "NotificationsView_DeleteNotification_Fail"
            }
        }

        var parameters: [String: Any]? {
            switch self {
            case .markAsReadStart(let notification),
                 .markAsReadSuccess(let notification),
                 .deleteNotificationStart(let notification),
                 .deleteNotificationSuccess(let notification):
                notification.eventParameters
            case .markAsReadFail(let error, let notification),
                 .deleteNotificationFail(let error, let notification):
                notification.eventParameters.merging(error.eventParameters) { current, _ in current }
            case .fetchNotificationsFail(let error),
                 .markAllAsReadFail(let error):
                error.eventParameters
            default:
                nil
            }
        }

        var type: LogType {
            switch self {
            case .fetchNotificationsFail, .markAsReadFail,
                 .markAllAsReadFail, .deleteNotificationFail:
                .severe
            default:
                .analytic
            }
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
            ZStack {
                notificationBackground
                    .ignoresSafeArea()

                Group {
                    if viewModel.userNotifications.isEmpty {
                        emptyState
                    } else {
                        notificationsList
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                leadingToolbar
                trailingToolbar
            }
        }
        .presentationBackground(.clear)
        .onAppear {
            referenceDate = .now
        }
    }

    private var notificationBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.89, green: 0.95, blue: 1.00),
                    Color(red: 0.95, green: 0.89, blue: 0.98),
                    Color(red: 0.91, green: 0.96, blue: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 240, height: 240)
                .blur(radius: 45)
                .offset(x: 170, y: -260)

            Circle()
                .fill(Color.purple.opacity(0.10))
                .frame(width: 240, height: 240)
                .blur(radius: 45)
                .offset(x: -170, y: 260)
        }
    }

    // MARK: - List

    private var notificationsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if !todayNotifications.isEmpty {
                    notificationSection(
                        title: "Today",
                        notifications: todayNotifications
                    )
                }

                if !earlierNotifications.isEmpty {
                    notificationSection(
                        title: "Earlier",
                        notifications: earlierNotifications
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private func notificationSection(
        title: String,
        notifications: [NotificationModel]
    ) -> some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.primary.opacity(0.58))
            .textCase(.uppercase)
            .padding(.horizontal, 12)

        VStack(spacing: 0) {
            ForEach(notifications) { notification in
                HouseMateSwipeRow(
                    leadingAction: deleteAction(for: notification),
                    trailingAction: nil
                ) {
                    NotificationRowView(
                        notification: notification,
                        referenceDate: referenceDate
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        openNotification(notification)
                    }
                }
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.88))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.62), lineWidth: 0.8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func deleteAction(for notification: NotificationModel) -> HouseMateSwipeAction {
        HouseMateSwipeAction(
            accessibilityLabel: "Delete notification",
            systemImage: "trash.fill",
            color: .red
        ) {
            Task {
                _ = await viewModel.deleteNotification(notification)
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
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.semibold))
            }
        }
    }

    @ToolbarContentBuilder
    private var trailingToolbar: some ToolbarContent {
        if viewModel.unreadCount > 0 {
            ToolbarItem(
                placement: .confirmationAction
            ) {
                Button {
                    Task {
                        _ = await viewModel.markAllAsRead()
                    }
                } label: {
                    Text("Read all")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
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

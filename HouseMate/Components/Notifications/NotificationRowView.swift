//
//  NotificationRowView.swift
//  HouseMate
//
//  Created by Marcin Turek on 24/08/2026.
//


import SwiftUI

struct NotificationRowView: View {

    let notification: NotificationModel
    let referenceDate: Date

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            notificationIcon

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(
                            notification.isRead
                                ? .medium
                                : .semibold
                        )

                    Spacer()

                    Text(relativeDateText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(notification.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }

    // MARK: - Icon

    private var notificationIcon: some View {
        Image(systemName: notification.type.systemImage)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(notificationColor)
            .frame(width: 40, height: 40)
            .background {
                RoundedRectangle(
                    cornerRadius: 13,
                    style: .continuous
                )
                .fill(notificationColor.opacity(0.12))
            }
    }

    private var notificationColor: Color {
        switch notification.type {
        case .taskAssigned:
            return .purple

        case .taskDue:
            return .blue

        case .billDue:
            return .orange

        case .newPoll:
            return .cyan

        case .houseReminder:
            return .green

        case .newBoardPost:
            return .indigo

        case .householdInvitation:
            return .pink
        }
    }

    // MARK: - Date

    private var relativeDateText: String {
        guard let createdAt = notification.createdAt else {
            return ""
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated

        return formatter.localizedString(
            for: createdAt,
            relativeTo: referenceDate
        )
    }
}

// MARK: - Preview

#Preview {
    NotificationRowView(
        notification: NotificationModel.mock,
        referenceDate: .now
    )
    .padding()
}

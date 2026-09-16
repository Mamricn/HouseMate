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
                        .lineLimit(1)
                        .layoutPriority(1)
                        .fontWeight(
                            notification.isRead
                                ? .medium
                                : .semibold
                        )

                    Spacer()

                    Text(relativeDateText)
                        .font(.caption2)
                        .foregroundStyle(Color.primary.opacity(0.48))
                        .fixedSize(horizontal: true, vertical: false)
                }

                Text(notification.message)
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.56))
                    .lineLimit(2)
            }

            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.leading, 52)
                .opacity(0.55)
        }
    }

    // MARK: - Icon

    private var notificationIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [notificationColor.opacity(0.92), notificationColor.opacity(0.62)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(.white.opacity(0.22))
                .frame(width: 24, height: 24)
                .offset(x: 13, y: -13)

            Image(systemName: notification.type.systemImage)
                .font(.system(size: 17, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)
        }
        .frame(width: 40, height: 40)
        .shadow(color: notificationColor.opacity(0.20), radius: 5, y: 3)
    }

    private var notificationColor: Color {
        switch notification.type {
        case .taskAssigned:
            return .purple

        case .taskDue:
            return .blue

        case .newBill, .billDue:
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

//
//  ComingUpCardView.swift
//  HouseMate
//
//  Created by Marcin Turek on 26/08/2026.
//

import SwiftUI

struct ComingUpItem: Identifiable, Equatable {

    enum Kind: Equatable {
        case task
        case reminder
    }

    let id: String
    let title: String
    let subtitle: String
    let date: Date
    let systemImage: String
    let kind: Kind
}

struct ComingUpCardView: View {

    let items: [ComingUpItem]

    private let calendar = Calendar.autoupdatingCurrent

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if items.isEmpty {
                emptyState
            } else {
                itemsList
            }
        }
        .padding()
        .background {
            cardBackground
        }
    }

    private var header: some View {
        HStack {
            Text("Coming Up")
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.headline)
                .foregroundStyle(.blue)
        }
    }

    private var itemsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                itemRow(item)

                if index < items.count - 1 {
                    Divider()
                        .padding(.leading, 54)
                }
            }
        }
    }

    private func itemRow(_ item: ComingUpItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(color(for: item.kind))
                .frame(width: 40, height: 40)
                .background {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(color(for: item.kind).opacity(0.12))
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(dateText(item.date))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.checkmark")
                .foregroundStyle(.green)

            Text("Nothing coming up")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private func dateText(_ date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Today"
        }

        if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }

        return date.formatted(
            .dateTime
                .weekday(.abbreviated)
                .day()
                .month(.abbreviated)
        )
    }

    private func color(for kind: ComingUpItem.Kind) -> Color {
        switch kind {
        case .task:
            return .blue

        case .reminder:
            return .orange
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.ultraThickMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.85), lineWidth: 1)
            }
    }
}

#Preview("Coming Up") {
    ComingUpCardView(
        items: [
            ComingUpItem(
                id: "reminder_1",
                title: "General waste collection",
                subtitle: "General Waste",
                date: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now,
                systemImage: "trash.fill",
                kind: .reminder
            ),
            ComingUpItem(
                id: "task_1",
                title: "Clean the kitchen",
                subtitle: "Your task",
                date: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now,
                systemImage: "fork.knife",
                kind: .task
            )
        ]
    )
    .padding()
}

#Preview("Empty") {
    ComingUpCardView(items: [])
        .padding()
}

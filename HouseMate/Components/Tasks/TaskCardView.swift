//
//  TaskCardView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import SwiftUI

struct TaskCardView: View {

    let tasks: [TaskModel]

    var showsAddButton: Bool = true
    var usesThinMaterial: Bool = true
    var onOpenAll: () -> Void = {}
    var onToggleStatus: (TaskModel) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if tasks.isEmpty {
                Text("No tasks for today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                tasksList
            }
        }
        .padding()
        .background {
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .fill(usesThinMaterial ? Material.ultraThin : Material.ultraThick)
            .overlay {
                RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
                .stroke(.white.opacity(0.85), lineWidth: 1)
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                HapticFeedback.selection()
                onOpenAll()
            } label: {
                HStack {
                    Text("Today's Tasks")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary.opacity(0.7))
                }
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open all household tasks")

            if showsAddButton {
                Button {

                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private var tasksList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(tasks) { task in
                    TaskRowView(task: task)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            HapticFeedback.selection()
                            onToggleStatus(task)
                        }
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: min(CGFloat(tasks.count) * 58, 180))
    }
}

#Preview("With Tasks") {
    TaskCardView(
        tasks: TaskModel.mockList
    )
    .padding()
}

#Preview("Empty") {
    TaskCardView(
        tasks: []
    )
    .padding()
}

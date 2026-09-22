//
//  TaskCardView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import SwiftUI

struct TaskCardView: View {

    let tasks: [TaskModel]

    @State private var completingTaskIDs: Set<String> = []

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
                    TaskRowView(task: displayedTask(for: task))
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            )
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard !completingTaskIDs.contains(task.id) else {
                                return
                            }

                            HapticFeedback.selection()

                            withAnimation(.snappy(duration: 0.22)) {
                                _ = completingTaskIDs.insert(task.id)
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                onToggleStatus(task)
                            }
                        }
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: min(CGFloat(tasks.count) * 58, 180))
        .animation(.snappy(duration: 0.3), value: tasks.map(\.id))
    }

    private func displayedTask(for task: TaskModel) -> TaskModel {
        guard completingTaskIDs.contains(task.id) else {
            return task
        }

        var completedTask = task
        completedTask.status = .completed
        return completedTask
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

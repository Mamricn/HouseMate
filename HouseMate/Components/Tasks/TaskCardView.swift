//
//  TaskCardView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import SwiftUI

struct TaskCardView: View {

    let tasks: [TaskModel]
    let members: [HouseholdMemberModel]

    var showsAddButton: Bool = true
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
            .fill(.ultraThickMaterial)
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
            Text("Today's Tasks")
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            if showsAddButton {
                Button {

                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private var tasksList: some View {
        List(tasks) { task in
            let member = members.first {
                $0.userId == task.assignedToUserId
            }

            TaskRowView(
                task: task,
                member: member
            )
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .swipeActions(
                edge: .trailing,
                allowsFullSwipe: true
            ) {
                Button {
                    onToggleStatus(task)
                } label: {
                    Label(
                        task.status == .completed
                            ? "Mark Pending"
                            : "Complete",
                        systemImage: task.status == .completed
                            ? "arrow.uturn.backward.circle"
                            : "checkmark.circle"
                    )
                }
                .tint(
                    task.status == .completed
                        ? .orange
                        : .green
                )
            }
            .roundedSwipeActions()
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .frame(height: 140)
    }
}

#Preview("With Tasks") {
    TaskCardView(
        tasks: TaskModel.mockList,
        members: HouseholdMemberModel.mockList
    )
    .padding()
}

#Preview("Empty") {
    TaskCardView(
        tasks: [],
        members: HouseholdMemberModel.mockList
    )
    .padding()
}

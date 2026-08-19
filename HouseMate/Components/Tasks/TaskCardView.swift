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

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Text("Today's Tasks")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button {

                } label: {
                    Image(systemName: "plus")
                }
            }

            if tasks.isEmpty {
                Text("No tasks for today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 3) {
                        ForEach(tasks) { task in
                            let member = members.first {
                                $0.userId == task.assignedToUserId
                            }

                            TaskRowView(
                                task: task,
                                member: member
                            )
                        }
                    }
                }
                .frame(height: 100)
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
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
                .stroke(.white.opacity(0.45), lineWidth: 1)
            }
        }
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

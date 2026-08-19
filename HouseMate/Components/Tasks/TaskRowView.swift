//
//  TaskRowView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//


import SwiftUI

struct TaskRowView: View {
    
    let task: TaskModel
    let member: HouseholdMemberModel?
    
    var body: some View {
        HStack(spacing: 12) {
            
            Image(
                systemName: task.status == .completed
                ? "checkmark.circle.fill"
                : "circle"
            )
            .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                
                Text(task.title)
                    .font(.headline)
                
                HStack(spacing: 6) {
                    
                    if let member {
                        Text(member.displayName)
                    }
                    
                    if member != nil && task.dueDate != nil {
                        Text("•")
                    }
                    
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .date)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
//        .padding()
    }
}

#Preview {
    TaskRowView(
        task: .mock,
        member: .mock
    )
}

//
//  TaskRowView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//


import SwiftUI

struct TaskRowView: View {
    
    let task: TaskModel
    
    var body: some View {
        HStack(spacing: 12) {
            HouseMateSymbolView(
                systemName: categorySystemImage,
                color: categoryColor,
                size: 40,
                symbolSize: 17
            )

            VStack(alignment: .leading, spacing: 4) {
                
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .strikethrough(
                        task.status == .completed,
                        color: .secondary
                    )
                    .foregroundStyle(
                        task.status == .completed
                            ? .secondary
                            : .primary
                    )
                
                HStack(spacing: 6) {
                    Text(categoryTitle)

                    Text("•")

                    if task.isAllDay {
                        Text("All day")
                    } else if let dueDate = task.dueDate {
                        Text(dueDate, style: .time)
                    } else {
                        Text("No time")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()

            Image(
                systemName: task.status == .completed
                    ? "checkmark.circle"
                    : "circle"
            )
            .font(.title2)
            .foregroundStyle(
                task.status == .completed
                    ? .blue
                    : .secondary
            )
            .animation(.snappy(duration: 0.22), value: task.status)
        }
        .padding(.vertical, 8)
    }

    private var categoryTitle: String {
        switch task.category {
        case .cleaning:
            return "Cleaning"
        case .kitchen:
            return "Kitchen"
        case .bathroom:
            return "Bathroom"
        case .laundry:
            return "Laundry"
        case .trash:
            return "Trash"
        case .shopping:
            return "Shopping"
        case .other:
            return "Other"
        }
    }

    private var categorySystemImage: String {
        switch task.category {
        case .cleaning: return "sparkles"
        case .kitchen: return "fork.knife"
        case .bathroom: return "shower.fill"
        case .laundry: return "washer.fill"
        case .trash: return "trash.fill"
        case .shopping: return "cart.fill"
        case .other: return "checklist"
        }
    }

    private var categoryColor: Color {
        switch task.category {
        case .cleaning: return .blue
        case .kitchen: return .orange
        case .bathroom: return .cyan
        case .laundry: return .purple
        case .trash: return .green
        case .shopping: return .pink
        case .other: return .gray
        }
    }
}

#Preview {
    TaskRowView(
        task: .mock
    )
}

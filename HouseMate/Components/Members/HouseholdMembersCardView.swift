//
//  HouseholdMembersCardView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//


import SwiftUI

struct HouseholdMembersCardView: View {

    let members: [HouseholdMemberModel]

    var showsAddButton: Bool = true
    var onAdd: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if members.isEmpty {
                emptyState
            } else {
                membersList
            }
        }
        .padding()
        .background {
            cardBackground
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Household Members")
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            if showsAddButton {
                Button {
                    onAdd()
                } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.headline)
                }
            }
        }
    }

    // MARK: - Members

    private var membersList: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 16) {
                ForEach(members) { member in
                    MemberView(member: member)
                }
            }
        }
        .frame(height: 80)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.3")
                .font(.system(size: 28))
                .foregroundStyle(.blue)

            Text("No household members")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Invite someone to join your home.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }

    // MARK: - Background

    private var cardBackground: some View {
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
            .stroke(
                .white.opacity(0.35),
                lineWidth: 1
            )
        }
    }
}

// MARK: - Previews

#Preview("Members") {
    HouseholdMembersCardView(
        members: HouseholdMemberModel.mockList,
        onAdd: {
            print("Invite housemate")
        }
    )
    .padding()
}

#Preview("Empty") {
    HouseholdMembersCardView(
        members: []
    )
    .padding()
}

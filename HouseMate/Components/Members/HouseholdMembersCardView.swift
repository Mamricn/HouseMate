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
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                Text("Household")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if showsAddButton {
                    Button {
                        
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            
            if members.isEmpty {
                Text("No household members")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 16) {
                        ForEach(members) { member in
                            MemberView(member: member)
                        }
                    }
                }
                .frame(height: 80)
                .scrollIndicators(.hidden)
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
}

#Preview("With Members") {
    HouseholdMembersCardView(
        members: HouseholdMemberModel.mockList
    )
    .padding()
}

#Preview("Empty") {
    HouseholdMembersCardView(members: [])
        .padding()
}

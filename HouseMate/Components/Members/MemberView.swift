//
//  MemberView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import SwiftUI

struct MemberView: View {
    
    let member: HouseholdMemberModel
    
    var body: some View {
        VStack(spacing: 6) {
            
            CachedProfileImage(
                urlString: member.profileImageUrl,
                displayName: member.displayName,
                size: 42
            )
            
            Text(member.displayName)
                .font(.caption)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}
#Preview {
    MemberView(member: HouseholdMemberModel.mock)
}

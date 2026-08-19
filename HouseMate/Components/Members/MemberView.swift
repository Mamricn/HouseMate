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
            
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 38))
                .foregroundStyle(.secondary)
            
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

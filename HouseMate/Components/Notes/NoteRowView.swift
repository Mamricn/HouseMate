//
//  NoteRowView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import SwiftUI

struct NoteRowView: View {
    
    let note: NoteModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            
            Image(systemName: note.category.systemImage)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(.thinMaterial)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                
                if let title = note.title {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
                
                Text(note.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

#Preview {
    NoteRowView(note: NoteModel.mock)
        .padding()
}

//
//  NotesCardView.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//

import SwiftUI

struct NotesCardView: View {

    let notes: [NoteModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Text("Notes")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button {

                } label: {
                    Image(systemName: "plus")
                }
            }

            if notes.isEmpty {

                Text("No notes yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            } else {

                ScrollView(.vertical) {
                    LazyVStack(spacing: 12) {
                        ForEach(notes) { note in
                            NoteRowView(note: note)
                        }
                    }
                }
                .frame(height: 140)
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
                .stroke(.white.opacity(0.85), lineWidth: 1)
            }
        }
    }
}

#Preview("With Notes") {
    NotesCardView(notes: NoteModel.mockList)
        .padding()
}

#Preview("Empty") {
    NotesCardView(notes: [])
        .padding()
}

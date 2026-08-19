//
//  NoteModel.swift
//  HouseMate
//
//  Created by Marcin Turek on 19/08/2026.
//


import Foundation

struct NoteModel: Identifiable, Codable, Equatable {
    
    var id: String { noteId }
    
    let noteId: String
    let householdId: String
    let createdAt: Date?
    
    var title: String?
    var content: String
    var createdByUserId: String
    var category: NoteCategory
    
    
    init(
        noteId: String,
        householdId: String,
        createdAt: Date? = nil,
        title: String? = nil,
        content: String,
        createdByUserId: String,
        category: NoteCategory = .other
    ) {
        self.noteId = noteId
        self.householdId = householdId
        self.createdAt = createdAt
        self.title = title
        self.content = content
        self.createdByUserId = createdByUserId
        self.category = category
    }
    
    
    enum CodingKeys: String, CodingKey {
        case noteId = "note_id"
        case householdId = "household_id"
        case createdAt = "created_at"
        case title
        case content
        case createdByUserId = "created_by_user_id"
        case category
    }
    
    
    var eventParameters: [String: Any] {
        
        let dict: [String: Any?] = [
            "note_\(CodingKeys.noteId.rawValue)": noteId,
            "note_\(CodingKeys.householdId.rawValue)": householdId,
            "note_\(CodingKeys.createdAt.rawValue)": createdAt,
            "note_\(CodingKeys.title.rawValue)": title,
            "note_\(CodingKeys.content.rawValue)": content,
            "note_\(CodingKeys.createdByUserId.rawValue)": createdByUserId,
            "note_\(CodingKeys.category.rawValue)": category.rawValue
        ]
        
        return dict.compactMapValues { $0 }
    }
}


// MARK: - Note Category

enum NoteCategory: String, Codable, CaseIterable {
    
    case shopping
    case maintenance
    case reminder
    case house
    case important
    case other
    
    var systemImage: String {
        switch self {
        case .shopping:
            return "cart.fill"
            
        case .maintenance:
            return "wrench.and.screwdriver.fill"
            
        case .reminder:
            return "bell.fill"
            
        case .house:
            return "house.fill"
            
        case .important:
            return "exclamationmark.circle.fill"
            
        case .other:
            return "note.text"
        }
    }
}


// MARK: - Mock Data

extension NoteModel {
    
    static let mock = NoteModel(
        noteId: "note_1",
        householdId: "house_123",
        createdAt: .now,
        title: "This week",
        content: "Plumber coming Friday at 10am.",
        createdByUserId: "user_1",
        category: .maintenance
    )
    
    
    static let mockList: [NoteModel] = [
        
        NoteModel(
            noteId: "note_1",
            householdId: "house_123",
            createdAt: .now,
            title: "Shopping",
            content: "Remember to buy dishwasher tablets.",
            createdByUserId: "user_1",
            category: .shopping
        ),
        
        NoteModel(
            noteId: "note_2",
            householdId: "house_123",
            createdAt: .now,
            title: "Friday",
            content: "Plumber coming at 10am.",
            createdByUserId: "user_2",
            category: .maintenance
        )
    ]
}

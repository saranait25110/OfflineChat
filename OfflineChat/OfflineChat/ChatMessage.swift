//
//  ChatMessage.swift
//  OfflineChat
//
//  Created by Saranya iOS on 03/09/25.
//

import Foundation

// MARK: - Message Model
struct ChatMessage: Codable, Equatable, Identifiable {
    let id: String
    let senderName: String
    var content: String
    let timestamp: Date
    var isEdited: Bool
    var isDeleted: Bool
    
    // Initializer for new messages
    init(senderName: String, content: String) {
        self.id = UUID().uuidString
        self.senderName = senderName
        self.content = content
        self.timestamp = Date()
        self.isEdited = false
        self.isDeleted = false
    }
    
    // Initializer for system use (edit/delete cases)
    init(id: String, senderName: String, content: String, timestamp: Date, isEdited: Bool = false, isDeleted: Bool = false) {
        self.id = id
        self.senderName = senderName
        self.content = content
        self.timestamp = timestamp
        self.isEdited = isEdited
        self.isDeleted = isDeleted
    }
}

// MARK: - Message Extensions
extension ChatMessage {
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
//    var displayContent: String {
//        if isDeleted {
//            return "Message deleted"
//        }
//        return content + (isEdited ? " (edited)" : "")
//    }
}

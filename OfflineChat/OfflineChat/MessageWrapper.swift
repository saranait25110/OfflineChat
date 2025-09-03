//
//  MessageWrapper.swift
//  OfflineChat
//
//  Created by Saranya iOS on 03/09/25.
//
//


import Foundation

// MARK: - Message Actions
enum MessageAction: String, Codable {
    case new
    case edit
    case delete
}

// MARK: - Message Wrapper
struct MessageWrapper: Codable {
    let action: MessageAction
    let message: ChatMessage
}


//
//  Chat.swift
//  TestApp
//
//  Created by Claude on 12.01.2026.
//

import Foundation

struct Chat: Codable, Identifiable {
    let id: Int
    let chatType: String
    let name: String?
    let avatar: String?
    let participants: [User]?
    let lastMessage: Message?
    let unreadCount: Int?
    let isInInbox: Bool?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case chatType = "chat_type"
        case name
        case avatar
        case participants
        case lastMessage = "last_message"
        case unreadCount = "unread_count"
        case isInInbox = "is_in_inbox"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var displayName: String {
        if let name = name {
            return name
        }
        if let participants = participants, !participants.isEmpty {
            return participants.map { $0.displayName }.joined(separator: ", ")
        }
        return "Chat \(id)"
    }

    var otherParticipant: User? {
        participants?.first
    }
}

struct ChatListResponse: Codable {
    let chats: [Chat]
    let total: Int
    let offset: Int
    let limit: Int
}

struct ChatResponse: Codable {
    let chat: Chat
    let messages: [Message]
}

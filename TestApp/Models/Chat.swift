//
//  Chat.swift
//  TestApp
//
//  Created by Тадевос Курдоглян on 12.01.2026.
//

import Foundation

struct Chat: Codable, Identifiable {
    let id: Int
    let chatType: String? // maps from "type"
    let name: String?
    let avatarURL: String? // maps from "avatar_url"
    let otherUser: User? // maps from "other_user"
    let participants: [User]? // keep for other endpoints that may return participants
    let lastMessage: Message? // maps from "last_message"
    let unreadCount: Int?
    let isInInbox: Bool?
    let inboxReason: String?
    let createdAt: String?
    let updatedAt: String?
    let foundMessage: Message?
    let totalMatchesInChat: Int?
    var isArchived: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case chatType = "type"
        case name
        case avatarURL = "avatar_url"
        case otherUser = "other_user"
        case participants
        case lastMessage = "last_message"
        case unreadCount = "unread_count"
        case isInInbox = "is_in_inbox"
        case inboxReason = "inbox_reason"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case foundMessage = "found_message"
        case totalMatchesInChat = "total_matches_in_chat"
        case isArchived = "is_archived"
    }

    var displayName: String {
        if let name = name, !name.isEmpty {
            return name
        }
        if let other = otherUser {
            return other.displayName
        }
        if let participants = participants, !participants.isEmpty {
            return participants.map { $0.displayName }.joined(separator: ", ")
        }
        return "Chat \(id)"
    }

    // Prefer explicit other user if present, fallback to first participant
    var otherParticipant: User? {
        if let other = otherUser { return other }
        return participants?.first
    }
}

struct ChatListResponse: Codable {
    let chats: [Chat]
    let count: Int

    enum CodingKeys: String, CodingKey {
        case chats
        case count
    }
}

struct ChatResponse: Codable {
    let chat: Chat
    let messages: [Message]
}

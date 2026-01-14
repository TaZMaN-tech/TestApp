//
//  Message.swift
//  TestApp
//
//  Created by Claude on 12.01.2026.
//

import Foundation

struct Message: Codable, Identifiable {
    let id: Int
    let chatId: Int? // optional: not present in last_message payloads
    let senderId: Int
    let messageType: String? // optional: may be absent in some responses
    let content: String?
    let files: [MessageFile]?
    let videoId: Int? // present in some responses
    let nomenclatureId: Int? // present in some responses
    let isRead: Bool?
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case chatId = "chat_id"
        case senderId = "sender_id"
        case messageType = "message_type"
        case content
        case files
        case videoId = "video_id"
        case nomenclatureId = "nomenclature_id"
        case isRead = "is_read"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var isIncoming: Bool {
        return senderId != AuthManager.shared.currentUserId
    }
}

struct MessageFile: Codable {
    let id: String
    let url: String
    let fileName: String?
    let fileSize: Int?
    let mimeType: String?

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case fileName = "file_name"
        case fileSize = "file_size"
        case mimeType = "mime_type"
    }
}

struct MessageSendRequest: Codable {
    let recipientId: Int?
    let username: String?
    let phoneNumber: String?
    let messageType: String
    let content: String?
    let files: [String]?

    enum CodingKeys: String, CodingKey {
        case recipientId = "recipient_id"
        case username
        case phoneNumber = "phone_number"
        case messageType = "message_type"
        case content
        case files
    }
}

struct MessageSendResponse: Codable {
    let messageId: Int
    let status: String

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case status
    }
}

struct MessageListResponse: Codable {
    let messages: [Message]
    let count: Int

    enum CodingKeys: String, CodingKey {
        case messages
        case count
    }
}

struct ChatSubscription: Codable {
    let token: String
    let channel: String
    let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case token
        case channel
        case expiresAt = "expires_at"
    }
}

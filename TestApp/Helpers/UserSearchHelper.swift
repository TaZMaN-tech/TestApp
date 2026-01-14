//
//  UserSearchHelper.swift
//  TestApp
//
//  Created by Claude on 12.01.2026.
//

import Foundation

class UserSearchHelper {
    static func findUserInChats(username: String, chats: [Chat]) -> Chat? {
        for chat in chats {
            if let participants = chat.participants {
                for participant in participants {
                    if participant.username == username {
                        return chat
                    }
                }
            }
            if let otherParticipant = chat.otherParticipant,
               otherParticipant.username == username {
                return chat
            }
        }
        return nil
    }

    static func createChatWithUsername(_ username: String) async throws -> Chat {
        let request = MessageSendRequest(
            recipientId: nil,
            username: username,
            phoneNumber: nil,
            messageType: "text",
            content: "Привет!",
            files: nil
        )

        let response = try await APIService.shared.sendMessage(request: request)
        let chatsResponse = try await APIService.shared.getChats(limit: 100)

        if let chat = chatsResponse.chats.first(where: { chat in
            if let participants = chat.participants {
                return participants.contains { $0.username == username }
            }
            return false
        }) {
            return chat
        }

        throw NSError(domain: "UserSearchHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Chat not found after message sent"])
    }

    static func createChatWithUser(_ user: User) async throws -> Chat {
        print("📤 Creating chat with user ID: \(user.id), name: \(user.name ?? "nil")")

        let request = MessageSendRequest(
            recipientId: user.id,
            username: nil,
            phoneNumber: nil,
            messageType: "text",
            content: "Привет!",
            files: nil
        )

        let response = try await APIService.shared.sendMessage(request: request)
        print("✅ Message sent successfully, response: \(response)")

        let chatsResponse = try await APIService.shared.getChats(limit: 100)
        print("📋 Retrieved \(chatsResponse.chats.count) chats")

        // Find chat by matching participant ID
        if let chat = chatsResponse.chats.first(where: { chat in
            return chat.otherParticipant?.id == user.id
        }) {
            print("✅ Found chat with user ID: \(user.id)")
            return chat
        }

        throw NSError(domain: "UserSearchHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Chat not found after message sent"])
    }
}

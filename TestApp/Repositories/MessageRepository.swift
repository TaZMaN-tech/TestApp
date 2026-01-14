//
//  MessageRepository.swift
//  TestApp
//
//  Created by Тадевос Курдоглян on 2026-01-14.
//

import Foundation

// MARK: - Protocol
protocol MessageRepository {
    func getMessages(chatId: Int, limit: Int, offset: Int) async throws -> [Message]
    func sendMessage(chatId: Int, content: String, attachments: [String]?) async throws -> Message
}

// MARK: - Default Implementation
final class DefaultMessageRepository: MessageRepository {

    private let apiService: APIService

    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    func getMessages(chatId: Int, limit: Int = 100, offset: Int = 0) async throws -> [Message] {
        let response = try await apiService.getChatMessages(chatId: chatId, offset: offset, limit: limit)
        return response.messages
    }

    func sendMessage(chatId: Int, content: String, attachments: [String]? = nil) async throws -> Message {
        // Note: API sendMessage returns MessageSendResponse with only messageId
        // We need to fetch the actual message after sending
        let request = MessageSendRequest(
            recipientId: nil,
            username: nil,
            phoneNumber: nil,
            messageType: "text",
            content: content,
            files: attachments
        )

        let response = try await apiService.sendMessage(request: request)

        // Fetch messages to get the actual Message object
        let messages = try await getMessages(chatId: chatId, limit: 1, offset: 0)

        // Find the message we just sent
        guard let sentMessage = messages.first(where: { $0.id == response.messageId }) else {
            // If we can't find it, create a placeholder message
            // This shouldn't happen but is a fallback
            throw NSError(
                domain: "MessageRepository",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Sent message not found in response"]
            )
        }

        return sentMessage
    }
}

//
//  ChatRepository.swift
//  TestApp
//
//  Created by Тадевос Курдоглян on 2026-01-14.
//

import Foundation

// MARK: - Protocol
protocol ChatRepository {
    func getChats(limit: Int, offset: Int) async throws -> [Chat]
    func getChat(id: Int) async throws -> Chat
    func archiveChat(id: Int) async throws
    func unarchiveChat(id: Int) async throws
    func searchUserByUsername(_ username: String) async throws -> User
}

// MARK: - Default Implementation
final class DefaultChatRepository: ChatRepository {

    private let apiService: APIService

    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    func getChats(limit: Int = 100, offset: Int = 0) async throws -> [Chat] {
        let response = try await apiService.getChats(offset: offset, limit: limit)
        return response.chats
    }

    func getChat(id: Int) async throws -> Chat {
        let response = try await apiService.getChat(id: id)
        return response.chat
    }

    func archiveChat(id: Int) async throws {
        try await apiService.moveChatToArchive(chatId: id)
    }

    func unarchiveChat(id: Int) async throws {
        try await apiService.moveChatToInbox(chatId: id)
    }

    func searchUserByUsername(_ username: String) async throws -> User {
        // Try searching by telegram username first, then by query
        var users: [User] = []

        do {
            users = try await apiService.searchUsersByTelegramUsername(telegramUsername: username)
        } catch {
            users = try await apiService.searchUsers(query: username)
        }

        guard let user = users.first else {
            throw NSError(
                domain: "ChatRepository",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "User not found"]
            )
        }

        return user
    }
}

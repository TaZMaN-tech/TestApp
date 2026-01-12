//
//  APIService.swift
//  TestApp
//
//  Created by Claude on 12.01.2026.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(String)
    case decodingError
    case networkError(Error)
}

class APIService {
    static let shared = APIService()
    private let baseURL = "https://interesnoitochka.ru/api/v1"

    private init() {}

    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        guard var urlComponents = URLComponents(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        if let queryItems = queryItems {
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = AuthManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = body
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
                    return try decoder.decode(T.self, from: data)
                } catch {
                    print("Decoding error: \(error)")
                    throw APIError.decodingError
                }
            case 401:
                throw APIError.unauthorized
            case 404:
                throw APIError.notFound
            default:
                if let errorString = String(data: data, encoding: .utf8) {
                    throw APIError.serverError(errorString)
                }
                throw APIError.serverError("Unknown error")
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    func createSession() async throws -> SessionResponse {
        let endpoint = "/auth/sessions/new"
        return try await request(endpoint: endpoint, method: "GET")
    }

    func refreshAccessToken(refreshToken: String) async throws -> TokenInfo {
        let endpoint = "/auth/jwt/refresh/new"

        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "token=\(refreshToken)".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.unauthorized
        }

        return try JSONDecoder().decode(TokenInfo.self, from: data)
    }

    func getCurrentUser() async throws -> User {
        let endpoint = "/auth/jwt/you"
        return try await request(endpoint: endpoint, method: "POST")
    }

    func getChats(offset: Int = 0, limit: Int = 20, search: String? = nil) async throws -> ChatListResponse {
        var queryItems = [
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }

        return try await request(endpoint: "/chats", queryItems: queryItems)
    }

    func getChat(id: Int) async throws -> ChatResponse {
        return try await request(endpoint: "/chats/\(id)")
    }

    func getChatMessages(chatId: Int, offset: Int = 0, limit: Int = 50) async throws -> MessageListResponse {
        let queryItems = [
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        return try await request(endpoint: "/chats/\(chatId)/messages", queryItems: queryItems)
    }

    func sendMessage(request: MessageSendRequest) async throws -> MessageSendResponse {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        return try await self.request(endpoint: "/chats/messages", method: "POST", body: body)
    }

    func getChatSubscription(chatId: Int) async throws -> ChatSubscription {
        return try await request(endpoint: "/chats/\(chatId)/subscribe")
    }

    func getAllChatsSubscription() async throws -> ChatSubscription {
        return try await request(endpoint: "/chats/subscribe/all")
    }

    func markChatAsRead(chatId: Int, lastMessageId: Int) async throws {
        struct ReadRequest: Codable {
            let lastReadMessageId: Int

            enum CodingKeys: String, CodingKey {
                case lastReadMessageId = "last_read_message_id"
            }
        }

        let readRequest = ReadRequest(lastReadMessageId: lastMessageId)
        let encoder = JSONEncoder()
        let body = try encoder.encode(readRequest)

        let _: EmptyResponse = try await request(endpoint: "/chats/\(chatId)/read", method: "POST", body: body)
    }
}

struct EmptyResponse: Codable {}

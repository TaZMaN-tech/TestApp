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

    func request<T: Decodable>(
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

        // Добавляем токен авторизации если есть
        if let token = AuthManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        // Если токена нет, но есть анонимная сессия, добавляем её
        else if let sessionId = AuthManager.shared.anonymousSessionId {
            request.setValue(sessionId, forHTTPHeaderField: "X-Session-ID")
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
                    print("❌ Decoding error: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📄 Response JSON: \(jsonString)")
                    }
                    throw APIError.decodingError
                }
            case 401:
                throw APIError.unauthorized
            case 404:
                throw APIError.notFound
            default:
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ Server error: \(errorString)")
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
        let endpoint = "/users/my"
        return try await request(endpoint: endpoint, method: "GET")
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

    func moveChatToInbox(chatId: Int) async throws {
        let _: EmptyResponse = try await request(endpoint: "/chats/\(chatId)/inbox", method: "PUT")
    }

    func moveChatToArchive(chatId: Int) async throws {
        let _: EmptyResponse = try await request(endpoint: "/chats/\(chatId)/archive", method: "PUT")
    }

    func sendTypingIndicator(chatId: Int) async throws {
        let _: EmptyResponse = try await request(endpoint: "/chats/\(chatId)/typing", method: "POST")
    }

    func uploadFiles(files: [Data], fileNames: [String]) async throws -> [MessageFile] {
        // Multipart form data upload
        let boundary = UUID().uuidString
        var body = Data()

        for (index, fileData) in files.enumerated() {
            let fileName = fileNames.indices.contains(index) ? fileNames[index] : "file\(index)"
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        guard let url = URL(string: "\(baseURL)/chats/messages/upload") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = AuthManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError("Upload failed")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([MessageFile].self, from: data)
    }

    func searchUsers(query: String) async throws -> [User] {
        struct UserSearchResponse: Codable {
            let users: [User]
        }

        let queryItems = [URLQueryItem(name: "q", value: query)]
        let response: UserSearchResponse = try await request(endpoint: "/users/search", queryItems: queryItems)
        return response.users
    }

    func getBotURL(sessionId: String) async throws -> String {
        guard var urlComponents = URLComponents(string: "\(baseURL)/bot_url") else {
            throw APIError.invalidURL
        }

        urlComponents.queryItems = [URLQueryItem(name: "session_id", value: sessionId)]

        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Добавляем X-Session-ID заголовок
        if let token = AuthManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if let sessionIdHeader = AuthManager.shared.anonymousSessionId {
            request.setValue(sessionIdHeader, forHTTPHeaderField: "X-Session-ID")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ /bot_url error: \(errorString)")
            }
            throw APIError.serverError("Failed to get bot URL")
        }

        // Попробуем декодировать как JSON объект
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📄 /bot_url response: \(jsonString)")

            // Попробуем разные форматы
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let botUrl = json["url"] as? String {
                return botUrl
            }

            // Если это просто строка в кавычках
            if let url = try? JSONDecoder().decode(String.self, from: data) {
                return url
            }

            // Если это просто текст без JSON
            return jsonString.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "")
        }

        throw APIError.decodingError
    }
}

struct EmptyResponse: Codable {}

//
//  User.swift
//  TestApp
//
//  Created by Claude on 12.01.2026.
//

import Foundation

struct User: Codable {
    let id: Int
    let username: String?
    let name: String?
    let firstName: String?
    let lastName: String?
    let avatar: String?
    let avatarUrl: String?
    let phoneNumber: String?
    let telegramUsername: String?
    let isOnline: Bool?
    let lastSeen: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case name
        case firstName = "first_name"
        case lastName = "last_name"
        case avatar
        case avatarUrl = "avatar_url"
        case phoneNumber = "phone_number"
        case telegramUsername = "telegram_username"
        case isOnline = "is_online"
        case lastSeen = "last_seen"
    }

    var displayName: String {
        if let name = name {
            return name
        }
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)"
        }
        return username ?? "User \(id)"
    }

    var avatarURL: String? {
        return avatarUrl ?? avatar
    }

    var lastSeenAt: Date? {
        guard let lastSeen = lastSeen else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: lastSeen)
    }
}

struct TokenInfo: Codable {
    let accessToken: String
    let refreshToken: String?
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
    }
}

struct AuthResponse: Codable {
    let user: User
    let tokens: TokenInfo
}

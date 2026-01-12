//
//  Session.swift
//  TestApp
//
//  Created by Claude on 12.01.2026.
//

import Foundation

struct SessionResponse: Codable {
    let id: String
    let lifetimeMinutes: Int
    let createdAt: String
    let expiresAt: String
    let refreshToken: String?
    let auth: Bool
    let tgId: Int?
    let userHashId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case lifetimeMinutes = "lifetime_minutes"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case refreshToken = "refresh_token"
        case auth
        case tgId = "tg_id"
        case userHashId = "user_hash_id"
    }
}

struct WebSocketTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

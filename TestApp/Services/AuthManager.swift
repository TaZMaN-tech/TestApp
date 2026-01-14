//
//  AuthManager.swift
//  TestApp
//
//  Created by Тадевос Курдоглян on 12.01.2026.
//

import Foundation

class AuthManager {
    static let shared = AuthManager()

    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let userIdKey = "userId"
    private let anonymousSessionIdKey = "anonymousSessionId"
    private let sessionExpiresAtKey = "sessionExpiresAt"

    private init() {}

    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: accessTokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: accessTokenKey) }
    }

    var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: refreshTokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: refreshTokenKey) }
    }

    var currentUserId: Int? {
        get {
            let id = UserDefaults.standard.integer(forKey: userIdKey)
            return id > 0 ? id : nil
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: userIdKey)
            } else {
                UserDefaults.standard.removeObject(forKey: userIdKey)
            }
        }
    }

    // Анонимная сессия
    var anonymousSessionId: String? {
        get {
            // Проверяем, не истекла ли сессия
            if let expiresAt = sessionExpiresAt, Date() >= expiresAt {
                clearAnonymousSession()
                return nil
            }
            return UserDefaults.standard.string(forKey: anonymousSessionIdKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: anonymousSessionIdKey) }
    }

    var sessionExpiresAt: Date? {
        get { UserDefaults.standard.object(forKey: sessionExpiresAtKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: sessionExpiresAtKey) }
    }

    var isAuthenticated: Bool {
        return accessToken != nil
    }

    var hasAnonymousSession: Bool {
        return anonymousSessionId != nil
    }

    func saveTokens(_ tokens: TokenInfo, userId: Int) {
        accessToken = tokens.accessToken
        refreshToken = tokens.refreshToken
        currentUserId = userId
        // При успешной авторизации удаляем анонимную сессию
        clearAnonymousSession()
    }

    func saveAnonymousSession(_ session: SessionResponse) {
        anonymousSessionId = session.id

        // Вычисляем дату истечения
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let expiresAt = formatter.date(from: session.expiresAt) {
            sessionExpiresAt = expiresAt
        }
    }

    func clearAnonymousSession() {
        anonymousSessionId = nil
        sessionExpiresAt = nil
    }

    func clearTokens() {
        accessToken = nil
        refreshToken = nil
        currentUserId = nil
        // Анонимную сессию не удаляем - она может быть нужна для повторной авторизации
    }

    func clearAll() {
        clearTokens()
        clearAnonymousSession()
    }
}

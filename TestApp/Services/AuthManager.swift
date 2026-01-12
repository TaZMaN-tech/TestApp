//
//  AuthManager.swift
//  TestApp
//
//  Created by Claude on 12.01.2026.
//

import Foundation

class AuthManager {
    static let shared = AuthManager()

    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let userIdKey = "userId"

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

    var isAuthenticated: Bool {
        return accessToken != nil
    }

    func saveTokens(_ tokens: TokenInfo, userId: Int) {
        accessToken = tokens.accessToken
        refreshToken = tokens.refreshToken
        currentUserId = userId
    }

    func clearTokens() {
        accessToken = nil
        refreshToken = nil
        currentUserId = nil
    }
}

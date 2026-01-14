//
//  MockData.swift
//  TestApp
//
//  Created by Тадевос Курдоглян on 12.01.2026.
//

import Foundation

class MockData {
    static let testAccessToken = "test_access_token_demo"
    static let testRefreshToken = "test_refresh_token_demo"

    static func enableTestMode() {
        let tokens = TokenInfo(
            accessToken: testAccessToken,
            refreshToken: testRefreshToken,
            tokenType: "Bearer"
        )
        AuthManager.shared.saveTokens(tokens, userId: 999)
    }
}

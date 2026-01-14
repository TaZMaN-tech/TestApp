//
//  UserRepository.swift
//  TestApp
//
//  Created by Тадевос Курдоглян on 2026-01-14.
//

import Foundation

// MARK: - Protocol
protocol UserRepository {
    func getCurrentUser() async throws -> User
}

// MARK: - Default Implementation
final class DefaultUserRepository: UserRepository {

    private let apiService: APIService

    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    func getCurrentUser() async throws -> User {
        return try await apiService.getCurrentUser()
    }
}

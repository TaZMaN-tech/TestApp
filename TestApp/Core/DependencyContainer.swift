//
//  DependencyContainer.swift
//  TestApp
//
//  Created by Тадевос Курдоглян on 2026-01-14.
//

import Foundation

/// Simple Dependency Injection container for managing app dependencies
/// Makes testing easier and reduces coupling between components
final class DependencyContainer {

    // MARK: - Singleton

    static let shared = DependencyContainer()

    private init() {}

    // MARK: - Services

    lazy var apiService: APIService = {
        return APIService.shared
    }()

    lazy var webSocketService: WebSocketService = {
        return WebSocketService.shared
    }()

    lazy var imageCacheService: ImageCacheService = {
        return ImageCacheService.shared
    }()

    lazy var authManager: AuthManager = {
        return AuthManager.shared
    }()

    lazy var sessionManager: SessionManager = {
        return SessionManager.shared
    }()

    // MARK: - Repositories

    lazy var chatRepository: ChatRepository = {
        return DefaultChatRepository(apiService: apiService)
    }()

    lazy var messageRepository: MessageRepository = {
        return DefaultMessageRepository(apiService: apiService)
    }()

    lazy var userRepository: UserRepository = {
        return DefaultUserRepository(apiService: apiService)
    }()

    // MARK: - Factory Methods

    /// Create ChatViewModel with injected dependencies
    func makeChatViewModel(chat: Chat) -> ChatViewModel {
        return ChatViewModel(
            chat: chat,
            messageRepository: messageRepository,
            webSocketService: webSocketService
        )
    }

    /// Create ChatsViewModel with injected dependencies
    func makeChatsViewModel() -> ChatsViewModel {
        return ChatsViewModel(
            chatRepository: chatRepository,
            userRepository: userRepository
        )
    }

    // MARK: - Testing Support

    /// Replace dependencies for testing
    /// WARNING: Only use this in test environment
    func reset() {
        #if DEBUG
        print("⚠️ DependencyContainer.reset() called - only use in tests!")
        #endif
    }
}

// MARK: - Property Wrapper for Dependency Injection

/// Property wrapper for automatic dependency injection
/// Usage: @Injected var chatRepository: ChatRepository
@propertyWrapper
struct Injected<T> {
    private let keyPath: KeyPath<DependencyContainer, T>

    var wrappedValue: T {
        return DependencyContainer.shared[keyPath: keyPath]
    }

    init(_ keyPath: KeyPath<DependencyContainer, T>) {
        self.keyPath = keyPath
    }
}

// MARK: - Usage Examples

/*
 Example 1: Using DependencyContainer directly
 ```swift
 class MyViewController {
     let viewModel: ChatViewModel

     init(chat: Chat) {
         self.viewModel = DependencyContainer.shared.makeChatViewModel(chat: chat)
     }
 }
 ```

 Example 2: Using @Injected property wrapper
 ```swift
 class MyService {
     @Injected(\.chatRepository) var chatRepository

     func loadChats() async throws {
         let chats = try await chatRepository.getChats(limit: 100, offset: nil)
     }
 }
 ```

 Example 3: For testing - create mock dependencies
 ```swift
 class MockChatRepository: ChatRepository {
     // ... implement mock methods
 }

 // In test:
 let container = DependencyContainer.shared
 container.chatRepository = MockChatRepository()
 ```
 */

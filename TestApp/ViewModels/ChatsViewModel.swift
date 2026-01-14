//
//  ChatsViewModel.swift
//  TestApp
//
//  Created by Тадевос Курдоглян on 2026-01-14.
//

import Foundation
import Combine

enum ChatsTab: String {
    case messages = "Сообщения"
    case archive = "Архив"
}

/// ViewModel for ChatsViewController
/// Manages chat list, search, tab filtering
final class ChatsViewModel {

    // MARK: - Published Properties

    @Published private(set) var chats: [Chat] = []
    @Published private(set) var filteredChats: [Chat] = []
    @Published private(set) var currentUser: User?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    @Published private(set) var currentTab: ChatsTab = .messages
    @Published var searchText: String = ""

    // MARK: - Dependencies

    private let chatRepository: ChatRepository
    private let userRepository: UserRepository
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        chatRepository: ChatRepository = DefaultChatRepository(),
        userRepository: UserRepository = DefaultUserRepository()
    ) {
        self.chatRepository = chatRepository
        self.userRepository = userRepository

        setupSearchBinding()
    }

    // MARK: - Public Methods

    /// Load current user
    func loadCurrentUser() async {
        do {
            let user = try await userRepository.getCurrentUser()
            currentUser = user
        } catch {
            self.error = error
            print("❌ Error loading current user: \(error)")
        }
    }

    /// Load chats list
    func loadChats() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let loadedChats = try await chatRepository.getChats(limit: 100, offset: 0)
            chats = loadedChats
            applyFilters()
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
            print("❌ Error loading chats: \(error)")
        }
    }

    /// Switch tab (Messages or Archive)
    func selectTab(_ tab: ChatsTab) {
        currentTab = tab
        applyFilters()
    }

    /// Search user by username and create/open chat
    func searchAndCreateChat(username: String) async throws -> Chat {
        // First check if chat with this user already exists
        if let existingChat = chats.first(where: {
            $0.otherParticipant?.username?.lowercased() == username.lowercased()
        }) {
            return existingChat
        }

        // Search user
        let user = try await chatRepository.searchUserByUsername(username)

        // Create chat by sending a message using UserSearchHelper
        let chat = try await UserSearchHelper.createChatWithUser(user)

        // Add to chats list
        chats.insert(chat, at: 0)
        applyFilters()

        return chat
    }

    /// Delete chat (just removes from UI, no API call)
    func deleteChat(at index: Int) async {
        guard index < filteredChats.count else { return }

        let chat = filteredChats[index]

        // Remove from both lists
        if let originalIndex = chats.firstIndex(where: { $0.id == chat.id }) {
            chats.remove(at: originalIndex)
        }
        applyFilters()
    }

    /// Archive chat
    func archiveChat(at index: Int) async {
        guard index < filteredChats.count else { return }

        let chat = filteredChats[index]

        do {
            try await chatRepository.archiveChat(id: chat.id)

            // Update chat in list
            if let originalIndex = chats.firstIndex(where: { $0.id == chat.id }) {
                var updatedChat = chats[originalIndex]
                updatedChat.isArchived = true
                chats[originalIndex] = updatedChat
            }
            applyFilters()
        } catch {
            self.error = error
            print("❌ Error archiving chat: \(error)")
        }
    }

    /// Unarchive chat
    func unarchiveChat(at index: Int) async {
        guard index < filteredChats.count else { return }

        let chat = filteredChats[index]

        do {
            try await chatRepository.unarchiveChat(id: chat.id)

            // Update chat in list
            if let originalIndex = chats.firstIndex(where: { $0.id == chat.id }) {
                var updatedChat = chats[originalIndex]
                updatedChat.isArchived = false
                chats[originalIndex] = updatedChat
            }
            applyFilters()
        } catch {
            self.error = error
            print("❌ Error unarchiving chat: \(error)")
        }
    }

    // MARK: - Private Methods

    private func setupSearchBinding() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }

    private func applyFilters() {
        var result = chats

        // Filter by tab (archive or messages)
        switch currentTab {
        case .messages:
            result = result.filter { !($0.isArchived ?? false) }
        case .archive:
            result = result.filter { $0.isArchived ?? false }
        }

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { chat in
                let displayName = chat.displayName.lowercased()
                let search = searchText.lowercased()
                return displayName.contains(search)
            }
        }

        filteredChats = result
    }
}

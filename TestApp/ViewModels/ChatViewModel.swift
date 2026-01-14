//
//  ChatViewModel.swift
//  TestApp
//
//  Created by Тадевос Курдоглян on 2026-01-14.
//

import Foundation
import Combine

/// ViewModel for ChatViewController
/// Manages messages, sending, loading, and WebSocket updates
final class ChatViewModel: NSObject {

    // MARK: - Published Properties

    @Published private(set) var messages: [Message] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isSending: Bool = false
    @Published private(set) var error: Error?
    @Published private(set) var lastSeenText: String?

    // MARK: - Dependencies

    private let chat: Chat
    private let messageRepository: MessageRepository
    private let webSocketService: WebSocketService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        chat: Chat,
        messageRepository: MessageRepository = DefaultMessageRepository(),
        webSocketService: WebSocketService = .shared
    ) {
        self.chat = chat
        self.messageRepository = messageRepository
        self.webSocketService = webSocketService
        super.init()

        setupWebSocket()
    }

    deinit {
        webSocketService.delegate = nil
        webSocketService.disconnect()
    }

    // MARK: - Public Methods

    /// Load messages for the chat
    func loadMessages() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let loadedMessages = try await messageRepository.getMessages(chatId: chat.id, limit: 100, offset: 0)
            // Messages come from API in reverse order (newest first), so we reverse to show oldest first
            messages = loadedMessages.reversed()
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
            print("❌ Error loading messages: \(error)")
        }
    }

    /// Send a message
    func sendMessage(_ content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isSending else { return }

        isSending = true
        error = nil

        do {
            let newMessage = try await messageRepository.sendMessage(
                chatId: chat.id,
                content: content,
                attachments: nil
            )

            // Add message to the end of the list (newest at bottom)
            messages.append(newMessage)
            isSending = false
        } catch {
            self.error = error
            isSending = false
            print("❌ Error sending message: \(error)")
        }
    }

    /// Get formatted last seen text for the chat participant
    func getLastSeenText() -> String? {
        guard let otherParticipant = chat.otherParticipant else { return nil }

        if otherParticipant.isOnline == true {
            return "в сети"
        }

        guard let lastSeenAt = otherParticipant.lastSeenAt else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: lastSeenAt, to: now)

        if let minutes = components.minute, minutes < 1 {
            return "был(а) недавно"
        } else if let minutes = components.minute, minutes < 60 {
            return "был(а) \(String(minutes)) мин. назад"
        } else if let hours = components.hour, hours < 24 {
            return "был(а) \(String(hours)) ч. назад"
        } else if let days = components.day, days < 7 {
            return "был(а) \(String(days)) д. назад"
        } else {
            return "был(а) давно"
        }
    }

    /// Get chat title (participant name or "Chat")
    var chatTitle: String {
        return chat.otherParticipant?.displayName ?? "Chat"
    }

    /// Get avatar URL for the participant
    var avatarURL: String? {
        return chat.avatarURL ?? chat.otherParticipant?.avatarURL
    }

    // MARK: - Private Methods

    private func setupWebSocket() {
        webSocketService.delegate = self

        // Get WebSocket subscription token
        Task {
            do {
                let response = try await APIService.shared.getChatSubscription(chatId: chat.id)
                let subscription = ChatSubscription(
                    token: response.token,
                    channel: response.channel,
                    expiresAt: response.expiresAt
                )
                webSocketService.connect(subscription: subscription)
            } catch {
                print("❌ Error getting WebSocket subscription: \(error)")
                self.error = error
            }
        }
    }

    private func addOrUpdateMessage(_ message: Message) {
        // Check if message already exists
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            // Update existing message
            messages[index] = message
        } else {
            // Add new message at the end (most recent at bottom)
            messages.append(message)
        }
    }
}

// MARK: - WebSocketServiceDelegate

extension ChatViewModel: WebSocketServiceDelegate {

    func webSocketDidConnect() {
        print("✅ WebSocket connected in ChatViewModel")
    }

    func webSocketDidDisconnect(error: Error?) {
        if let error = error {
            print("❌ WebSocket disconnected with error: \(error)")
            self.error = error
        } else {
            print("🔌 WebSocket disconnected")
        }
    }

    func webSocketDidReceiveMessage(_ message: Message) {
        print("📨 Received message via WebSocket: \(message.content)")

        // Only add messages for this chat
        if message.chatId == chat.id {
            addOrUpdateMessage(message)
        }
    }
}

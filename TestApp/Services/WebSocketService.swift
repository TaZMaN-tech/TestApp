//
//  WebSocketService.swift
//  TestApp
//
//  Created by Claude on 12.01.2026.
//

import Foundation

protocol WebSocketServiceDelegate: AnyObject {
    func webSocketDidConnect()
    func webSocketDidDisconnect(error: Error?)
    func webSocketDidReceiveMessage(_ message: Message)
}

class WebSocketService: NSObject {
    static let shared = WebSocketService()

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    weak var delegate: WebSocketServiceDelegate?

    private var isConnected = false
    private var shouldReconnect = true
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5

    private override init() {
        super.init()
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    func connect(subscription: ChatSubscription) {
        disconnect()
        shouldReconnect = true

        guard let url = URL(string: "wss://interesnoitochka.ru/connection/websocket") else {
            print("❌ Invalid WebSocket URL")
            return
        }

        print("🔌 Connecting to WebSocket: \(url.absoluteString)")
        print("🔑 Using token: \(subscription.token.prefix(20))...")
        print("📡 Channel: \(subscription.channel)")

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        webSocketTask = urlSession?.webSocketTask(with: request)
        webSocketTask?.resume()

        receiveMessage()

        // Отправляем connect message сразу после установки соединения
        // Centrifugo ожидает это сообщение первым
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }

            // Centrifugo v4+ использует формат с "id" для каждой команды
            let connectMessage: [String: Any] = [
                "id": 1,
                "connect": [
                    "token": subscription.token
                ]
            ]

            if let jsonData = try? JSONSerialization.data(withJSONObject: connectMessage),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 Sending connect message: \(jsonString)")
                self.send(text: jsonString)
            }
        }

        // После подключения подписываемся на канал
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            let subscribeMessage: [String: Any] = [
                "id": 2,
                "subscribe": [
                    "channel": subscription.channel
                ]
            ]

            if let jsonData = try? JSONSerialization.data(withJSONObject: subscribeMessage),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 Sending subscribe message to channel: \(subscription.channel)")
                print("📤 Subscribe JSON: \(jsonString)")
                self.send(text: jsonString)
            }
        }
    }

    func disconnect() {
        shouldReconnect = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        print("🔌 WebSocket disconnected")
    }

    private func send(text: String) {
        let message = URLSessionWebSocketTask.Message.string(text)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text: text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text: text)
                    }
                @unknown default:
                    break
                }

                self.receiveMessage()

            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self.handleDisconnect(error: error)
            }
        }
    }

    private func handleMessage(text: String) {
        print("📥 WebSocket received raw: \(text)")

        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("⚠️ Failed to parse WebSocket message as JSON")
            return
        }

        print("📊 Parsed JSON keys: \(json.keys.joined(separator: ", "))")

        // Обработка ping от сервера
        if json["ping"] != nil {
            print("🏓 Received ping, sending pong")
            let pongMessage: [String: Any] = [:]
            if let jsonData = try? JSONSerialization.data(withJSONObject: pongMessage),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                send(text: jsonString)
            }
            return
        }

        // Проверяем, есть ли поле "id" - ответ на команду
        if let id = json["id"] {
            print("📬 Response to command ID: \(id)")
        }

        // Centrifugo v4+ отвечает с полем "connect" на connect команду
        if let connectResult = json["connect"] as? [String: Any] {
            isConnected = true
            reconnectAttempts = 0
            let client = connectResult["client"] as? String ?? "unknown"
            let version = connectResult["version"] as? String ?? "unknown"
            print("✅ WebSocket connected successfully!")
            print("   Client ID: \(client)")
            print("   Version: \(version)")
            DispatchQueue.main.async {
                self.delegate?.webSocketDidConnect()
            }
        }

        // Обработка подписки
        if let subscribeResult = json["subscribe"] as? [String: Any] {
            let recoverable = subscribeResult["recoverable"] as? Bool ?? false
            print("✅ Subscribed to channel successfully (recoverable: \(recoverable))")
        }

        // Обработка ошибок
        if let error = json["error"] as? [String: Any] {
            let code = error["code"] as? Int ?? 0
            let message = error["message"] as? String ?? "Unknown error"
            print("❌ WebSocket error response:")
            print("   Code: \(code)")
            print("   Message: \(message)")
            if let id = json["id"] {
                print("   For command ID: \(id)")
            }
        }

        // Обработка push-уведомлений (новые сообщения)
        if let push = json["push"] as? [String: Any] {
            print("📨 Received push notification")
            print("   Push type: \(push["type"] ?? "unknown")")
            print("   Full push data: \(push)")

            if let channel = push["channel"] as? String {
                print("   Channel: \(channel)")
            }

            // Обработка pub (publication) - новое сообщение в канале
            if let pub = push["pub"] as? [String: Any] {
                print("   Pub data keys: \(pub.keys.joined(separator: ", "))")

                if let data = pub["data"] as? [String: Any] {
                    print("   Message data keys: \(data.keys.joined(separator: ", "))")

                    // Проверяем тип события
                    if let type = data["type"] as? String, type == "new_message" {
                        // Это новое сообщение - преобразуем в формат Message
                        var normalizedData: [String: Any] = [:]

                        // Преобразуем message_id -> id
                        if let messageId = data["message_id"] {
                            normalizedData["id"] = messageId
                        }

                        // Копируем остальные поля
                        if let chatId = data["chat_id"] {
                            normalizedData["chat_id"] = chatId
                        }
                        if let senderId = data["sender_id"] {
                            normalizedData["sender_id"] = senderId
                        }
                        if let content = data["content"] {
                            normalizedData["content"] = content
                        }
                        if let messageType = data["message_type"] {
                            normalizedData["message_type"] = messageType
                        }
                        if let replyToId = data["reply_to_id"] {
                            normalizedData["reply_to_id"] = replyToId
                        }
                        if let videoId = data["video_id"] {
                            normalizedData["video_id"] = videoId
                        }
                        if let nomenclatureId = data["nomenclature_id"] {
                            normalizedData["nomenclature_id"] = nomenclatureId
                        }

                        // Используем timestamp как created_at
                        if let timestamp = data["timestamp"] {
                            normalizedData["created_at"] = timestamp
                        }

                        do {
                            let messageJSON = try JSONSerialization.data(withJSONObject: normalizedData)
                            print("   Normalized message JSON: \(String(data: messageJSON, encoding: .utf8) ?? "nil")")
                            let message = try JSONDecoder().decode(Message.self, from: messageJSON)

                            print("📨 ✅ Decoded new message via WebSocket: ID=\(message.id), from=\(message.senderId), content=\(message.content?.prefix(30) ?? "nil")")
                            DispatchQueue.main.async {
                                self.delegate?.webSocketDidReceiveMessage(message)
                            }
                        } catch {
                            print("❌ Error decoding normalized message: \(error)")
                        }
                    } else {
                        print("   Skipping non-message event: \(data["type"] ?? "unknown")")
                    }
                }
            }

            // Старый формат для совместимости
            if let data = push["data"] as? [String: Any],
               let messageData = data["message"] as? [String: Any] {

                do {
                    let messageJSON = try JSONSerialization.data(withJSONObject: messageData)
                    let message = try JSONDecoder().decode(Message.self, from: messageJSON)

                    print("📨 Decoded new message via WebSocket (legacy format): ID=\(message.id)")
                    DispatchQueue.main.async {
                        self.delegate?.webSocketDidReceiveMessage(message)
                    }
                } catch {
                    print("❌ Error decoding message (legacy format): \(error)")
                }
            }
        }
    }

    private func handleDisconnect(error: Error?) {
        isConnected = false

        DispatchQueue.main.async {
            self.delegate?.webSocketDidDisconnect(error: error)
        }

        if shouldReconnect && reconnectAttempts < maxReconnectAttempts {
            reconnectAttempts += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self = self else { return }
            }
        }
    }

    func sendPing() {
        webSocketTask?.sendPing { error in
            if let error = error {
                print("WebSocket ping error: \(error)")
            }
        }
    }
}

extension WebSocketService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocolName: String?) {
        print("✅ WebSocketDidOpen - Protocol: \(protocolName ?? "none")")
        isConnected = true
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        var reasonString = "unknown"
        if let reason = reason, let str = String(data: reason, encoding: .utf8) {
            reasonString = str
        }
        print("❌ WebSocket didClose - Code: \(closeCode.rawValue), Reason: \(reasonString)")
        handleDisconnect(error: nil)
    }
}

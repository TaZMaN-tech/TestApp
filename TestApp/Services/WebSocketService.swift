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

        guard let url = URL(string: "wss://interesnoitochka.ru/connection/websocket") else {
            print("Invalid WebSocket URL")
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(subscription.token)", forHTTPHeaderField: "Authorization")

        webSocketTask = urlSession?.webSocketTask(with: request)
        webSocketTask?.resume()

        receiveMessage()

        let connectMessage: [String: Any] = [
            "connect": [
                "token": subscription.token,
                "name": "swift"
            ]
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: connectMessage),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            send(text: jsonString)
        }

        let subscribeMessage: [String: Any] = [
            "subscribe": [
                "channel": subscription.channel
            ]
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: subscribeMessage),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.send(text: jsonString)
            }
        }
    }

    func disconnect() {
        shouldReconnect = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
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
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        if json["connect"] != nil {
            isConnected = true
            reconnectAttempts = 0
            DispatchQueue.main.async {
                self.delegate?.webSocketDidConnect()
            }
        }

        if let push = json["push"] as? [String: Any],
           let data = push["data"] as? [String: Any],
           let messageData = data["message"] as? [String: Any] {

            do {
                let messageJSON = try JSONSerialization.data(withJSONObject: messageData)
                let message = try JSONDecoder().decode(Message.self, from: messageJSON)

                DispatchQueue.main.async {
                    self.delegate?.webSocketDidReceiveMessage(message)
                }
            } catch {
                print("Error decoding message: \(error)")
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
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket disconnected with code: \(closeCode)")
        handleDisconnect(error: nil)
    }
}

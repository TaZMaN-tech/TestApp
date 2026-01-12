//
//  AuthWebSocketService.swift
//  TestApp
//
//  Created by Claude on 12.01.2026.
//

import Foundation

protocol AuthWebSocketDelegate: AnyObject {
    func authWebSocketDidConnect()
    func authWebSocketDidReceiveTokens(accessToken: String, refreshToken: String)
    func authWebSocketDidFailWithError(_ error: Error)
}

class AuthWebSocketService: NSObject {
    weak var delegate: AuthWebSocketDelegate?
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?

    override init() {
        super.init()
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    func connect(sessionId: String) {
        disconnect()

        guard let url = URL(string: "wss://interesnoitochka.ru/api/v1/ws/ws/session/\(sessionId)") else {
            delegate?.authWebSocketDidFailWithError(NSError(domain: "AuthWebSocket", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        webSocketTask = urlSession?.webSocketTask(with: url)
        webSocketTask?.resume()

        receiveMessage()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
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
                DispatchQueue.main.async {
                    self.delegate?.authWebSocketDidFailWithError(error)
                }
            }
        }
    }

    private func handleMessage(text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        if let accessToken = json["access_token"] as? String,
           let refreshToken = json["refresh_token"] as? String {
            DispatchQueue.main.async {
                self.delegate?.authWebSocketDidReceiveTokens(accessToken: accessToken, refreshToken: refreshToken)
            }
        }
    }
}

extension AuthWebSocketService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Auth WebSocket connected")
        DispatchQueue.main.async {
            self.delegate?.authWebSocketDidConnect()
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Auth WebSocket disconnected")
    }
}

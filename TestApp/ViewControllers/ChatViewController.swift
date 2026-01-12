//
//  ChatViewController.swift
//  TestApp
//
//  Created by Claude on 12.01.2026.
//

import UIKit

class ChatViewController: UIViewController {

    private let chat: Chat
    private var messages: [Message] = []

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.register(MessageTableViewCell.self, forCellReuseIdentifier: MessageTableViewCell.identifier)
        table.separatorStyle = .none
        table.backgroundColor = .systemBackground
        table.keyboardDismissMode = .interactive
        table.transform = CGAffineTransform(scaleX: 1, y: -1)
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private let inputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let messageTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Сообщение..."
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .secondarySystemBackground
        textField.layer.cornerRadius = 20
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        textField.rightViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private var inputContainerBottomConstraint: NSLayoutConstraint!

    init(chat: Chat) {
        self.chat = chat
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardObservers()
        setupActions()
        loadMessages()
        setupWebSocket()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        WebSocketService.shared.delegate = nil
    }

    private func setupUI() {
        title = chat.displayName
        view.backgroundColor = .systemBackground

        view.addSubview(tableView)
        view.addSubview(inputContainerView)
        inputContainerView.addSubview(messageTextField)
        inputContainerView.addSubview(sendButton)
        inputContainerView.addSubview(activityIndicator)

        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.addSubview(separator)

        inputContainerBottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),

            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerBottomConstraint,
            inputContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),

            separator.topAnchor.constraint(equalTo: inputContainerView.topAnchor),
            separator.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            messageTextField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 12),
            messageTextField.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 8),
            messageTextField.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            messageTextField.heightAnchor.constraint(equalToConstant: 40),
            messageTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),

            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: messageTextField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func setupActions() {
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let keyboardHeight = keyboardFrame.height
        inputContainerBottomConstraint.constant = -keyboardHeight

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        inputContainerBottomConstraint.constant = 0

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    private func loadMessages() {
        activityIndicator.startAnimating()

        Task {
            do {
                let response = try await APIService.shared.getChatMessages(chatId: chat.id, limit: 100)

                await MainActor.run {
                    self.messages = response.messages.reversed()
                    self.activityIndicator.stopAnimating()
                    self.tableView.reloadData()
                }

                if let lastMessage = response.messages.first {
                    try? await APIService.shared.markChatAsRead(chatId: self.chat.id, lastMessageId: lastMessage.id)
                }
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.showError("Не удалось загрузить сообщения")
                }
            }
        }
    }

    private func setupWebSocket() {
        WebSocketService.shared.delegate = self

        Task {
            do {
                let subscription = try await APIService.shared.getChatSubscription(chatId: chat.id)
                WebSocketService.shared.connect(subscription: subscription)
            } catch {
                print("Failed to get WebSocket subscription: \(error)")
            }
        }
    }

    @objc private func sendButtonTapped() {
        guard let text = messageTextField.text, !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        sendMessage(text: text)
    }

    private func sendMessage(text: String) {
        messageTextField.isEnabled = false
        sendButton.isEnabled = false

        let request: MessageSendRequest
        if let recipientId = chat.otherParticipant?.id {
            request = MessageSendRequest(
                recipientId: recipientId,
                username: nil,
                phoneNumber: nil,
                messageType: "text",
                content: text,
                files: nil
            )
        } else if let username = chat.otherParticipant?.username {
            request = MessageSendRequest(
                recipientId: nil,
                username: username,
                phoneNumber: nil,
                messageType: "text",
                content: text,
                files: nil
            )
        } else {
            messageTextField.isEnabled = true
            sendButton.isEnabled = true
            return
        }

        Task {
            do {
                _ = try await APIService.shared.sendMessage(request: request)

                await MainActor.run {
                    self.messageTextField.text = ""
                    self.messageTextField.isEnabled = true
                    self.sendButton.isEnabled = true
                }
            } catch {
                await MainActor.run {
                    self.messageTextField.isEnabled = true
                    self.sendButton.isEnabled = true
                    self.showError("Не удалось отправить сообщение")
                }
            }
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MessageTableViewCell.identifier, for: indexPath) as? MessageTableViewCell else {
            return UITableViewCell()
        }

        let message = messages[indexPath.row]
        cell.configure(with: message)
        cell.transform = CGAffineTransform(scaleX: 1, y: -1)
        return cell
    }
}

extension ChatViewController: WebSocketServiceDelegate {
    func webSocketDidConnect() {
        print("WebSocket connected")
    }

    func webSocketDidDisconnect(error: Error?) {
        print("WebSocket disconnected: \(error?.localizedDescription ?? "unknown")")
    }

    func webSocketDidReceiveMessage(_ message: Message) {
        if message.chatId == chat.id {
            messages.insert(message, at: 0)
            tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)

            Task {
                try? await APIService.shared.markChatAsRead(chatId: chat.id, lastMessageId: message.id)
            }
        }
    }
}

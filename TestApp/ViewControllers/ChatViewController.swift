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
        table.backgroundColor = DesignSystem.Colors.primaryBackground
        table.keyboardDismissMode = .interactive
        table.transform = CGAffineTransform(scaleX: 1, y: -1)
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private let inputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = DesignSystem.Colors.primaryBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let messageTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Написать сообщение"
        textField.borderStyle = .none
        textField.backgroundColor = DesignSystem.Colors.secondaryBackground
        textField.textColor = DesignSystem.Colors.primaryText
        textField.layer.cornerRadius = DesignSystem.CornerRadius.medium
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        textField.rightViewMode = .always
        textField.font = DesignSystem.Fonts.body
        textField.attributedPlaceholder = NSAttributedString(
            string: "Написать сообщение",
            attributes: [.foregroundColor: DesignSystem.Colors.placeholderText]
        )
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let attachButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.tintColor = DesignSystem.Colors.secondaryText
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let emojiButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "face.smiling"), for: .normal)
        button.tintColor = DesignSystem.Colors.secondaryText
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        button.tintColor = DesignSystem.Colors.accentBlue
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
        view.backgroundColor = DesignSystem.Colors.primaryBackground

        // Настройка navigation bar
        navigationController?.navigationBar.barTintColor = DesignSystem.Colors.primaryBackground
        navigationController?.navigationBar.backgroundColor = DesignSystem.Colors.primaryBackground
        navigationController?.navigationBar.tintColor = DesignSystem.Colors.primaryText

        // Создаём кастомный title view с аватаром
        setupCustomTitleView()

        view.addSubview(tableView)
        view.addSubview(inputContainerView)
        inputContainerView.addSubview(attachButton)
        inputContainerView.addSubview(messageTextField)
        inputContainerView.addSubview(emojiButton)
        inputContainerView.addSubview(sendButton)
        inputContainerView.addSubview(activityIndicator)

        let separator = UIView()
        separator.backgroundColor = DesignSystem.Colors.separator
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

            // Attach button (слева)
            attachButton.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 12),
            attachButton.centerYAnchor.constraint(equalTo: messageTextField.centerYAnchor),
            attachButton.widthAnchor.constraint(equalToConstant: 28),
            attachButton.heightAnchor.constraint(equalToConstant: 28),

            // Text field (по центру)
            messageTextField.leadingAnchor.constraint(equalTo: attachButton.trailingAnchor, constant: 8),
            messageTextField.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 8),
            messageTextField.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            messageTextField.heightAnchor.constraint(equalToConstant: 40),
            messageTextField.trailingAnchor.constraint(equalTo: emojiButton.leadingAnchor, constant: -8),

            // Emoji button
            emojiButton.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            emojiButton.centerYAnchor.constraint(equalTo: messageTextField.centerYAnchor),
            emojiButton.widthAnchor.constraint(equalToConstant: 28),
            emojiButton.heightAnchor.constraint(equalToConstant: 28),

            // Send button (справа)
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: messageTextField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
    }

    private func setupCustomTitleView() {
        let titleView = UIView()
        titleView.translatesAutoresizingMaskIntoConstraints = false

        let avatarImageView = UIImageView()
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.backgroundColor = DesignSystem.Colors.secondaryBackground
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        nameLabel.text = chat.displayName
        nameLabel.font = DesignSystem.Fonts.title
        nameLabel.textColor = DesignSystem.Colors.primaryText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let statusLabel = UILabel()
        statusLabel.text = "онлайн"
        statusLabel.font = DesignSystem.Fonts.footnote
        statusLabel.textColor = DesignSystem.Colors.secondaryText
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        titleView.addSubview(avatarImageView)
        titleView.addSubview(nameLabel)
        titleView.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: titleView.leadingAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),

            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: DesignSystem.Spacing.small),
            nameLabel.topAnchor.constraint(equalTo: titleView.topAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: titleView.trailingAnchor),

            statusLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: DesignSystem.Spacing.small),
            statusLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            statusLabel.trailingAnchor.constraint(equalTo: titleView.trailingAnchor),

            titleView.heightAnchor.constraint(equalToConstant: 44),
            titleView.widthAnchor.constraint(equalToConstant: 200)
        ])

        navigationItem.titleView = titleView

        // Загружаем аватар
        if let avatarURL = chat.avatar ?? chat.otherParticipant?.avatar,
           let url = URL(string: avatarURL) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        await MainActor.run {
                            avatarImageView.image = image
                        }
                    }
                } catch {
                    avatarImageView.image = UIImage(systemName: "person.circle.fill")
                    avatarImageView.tintColor = DesignSystem.Colors.secondaryText
                }
            }
        } else {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            avatarImageView.tintColor = DesignSystem.Colors.secondaryText
        }
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func setupActions() {
        attachButton.addTarget(self, action: #selector(attachButtonTapped), for: .touchUpInside)
        emojiButton.addTarget(self, action: #selector(emojiButtonTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
    }

    @objc private func attachButtonTapped() {
        let alert = UIAlertController(title: "Прикрепить", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Фото или видео", style: .default) { [weak self] _ in
            self?.showImagePicker()
        })

        alert.addAction(UIAlertAction(title: "Файл", style: .default) { [weak self] _ in
            self?.showDocumentPicker()
        })

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func emojiButtonTapped() {
        // TODO: Реализовать выбор эмодзи
        print("Emoji button tapped")
    }

    private func showImagePicker() {
        // TODO: Реализовать UIImagePickerController
        print("Show image picker")
    }

    private func showDocumentPicker() {
        // TODO: Реализовать UIDocumentPickerViewController
        print("Show document picker")
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

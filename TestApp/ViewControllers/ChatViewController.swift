//
//  ChatViewController.swift
//  TestApp
//
//  Created by Тадевос Курдоглян on 12.01.2026.
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Скрываем TabBar при открытии чата
        tabBarController?.tabBar.isHidden = true

        // Показываем navigation bar
        navigationController?.setNavigationBarHidden(false, animated: animated)
        print("🔍 Navigation bar hidden: \(navigationController?.isNavigationBarHidden ?? true)")
        print("🔍 Navigation item title view: \(navigationItem.titleView != nil)")
    }

    private func adjustTableViewContentInset() {
        let contentHeight = tableView.contentSize.height
        let tableHeight = tableView.bounds.height

        if contentHeight < tableHeight {
            let inset = tableHeight - contentHeight
            tableView.contentInset = UIEdgeInsets(top: inset, left: 0, bottom: 0, right: 0)
        } else {
            tableView.contentInset = .zero
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Показываем TabBar при возврате к списку чатов
        tabBarController?.tabBar.isHidden = false

        // Отключаем WebSocket при выходе из чата
        WebSocketService.shared.disconnect()
        print("🔌 WebSocket disconnected on view disappear")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        WebSocketService.shared.delegate = nil
        WebSocketService.shared.disconnect()
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
            attachButton.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 16),
            attachButton.centerYAnchor.constraint(equalTo: messageTextField.centerYAnchor),
            attachButton.widthAnchor.constraint(equalToConstant: 28),
            attachButton.heightAnchor.constraint(equalToConstant: 28),

            // Text field (по центру)
            messageTextField.leadingAnchor.constraint(equalTo: attachButton.trailingAnchor, constant: 12),
            messageTextField.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 12),
            messageTextField.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            messageTextField.heightAnchor.constraint(equalToConstant: 40),
            messageTextField.trailingAnchor.constraint(equalTo: emojiButton.leadingAnchor, constant: -12),

            // Emoji button
            emojiButton.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -12),
            emojiButton.centerYAnchor.constraint(equalTo: messageTextField.centerYAnchor),
            emojiButton.widthAnchor.constraint(equalToConstant: 28),
            emojiButton.heightAnchor.constraint(equalToConstant: 28),

            // Send button (справа)
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -16),
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
        // Показываем статус онлайн из данных пользователя
        if let otherUser = chat.otherParticipant {
            if otherUser.isOnline == true {
                statusLabel.text = "онлайн"
                statusLabel.textColor = DesignSystem.Colors.accentBlue
            } else if let lastSeen = otherUser.lastSeen {
                statusLabel.text = formatLastSeen(lastSeen)
                statusLabel.textColor = DesignSystem.Colors.secondaryText
            } else {
                statusLabel.text = "был(а) недавно"
                statusLabel.textColor = DesignSystem.Colors.secondaryText
            }
        } else {
            statusLabel.text = "онлайн"
            statusLabel.textColor = DesignSystem.Colors.secondaryText
        }
        statusLabel.font = DesignSystem.Fonts.footnote
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
        if let avatarURL = chat.avatarURL ?? chat.otherParticipant?.avatarURL,
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

        // Добавляем делегат для текстового поля чтобы отслеживать изменения
        messageTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        // Изначально кнопка отправки неактивна
        updateSendButtonState()
    }

    @objc private func textFieldDidChange() {
        updateSendButtonState()
    }

    private func updateSendButtonState() {
        let hasText = !(messageTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        sendButton.isEnabled = hasText
        sendButton.alpha = hasText ? 1.0 : 0.5
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
                    let oldCount = self.messages.count
                    self.messages = response.messages.reversed()
                    self.activityIndicator.stopAnimating()

                    // Временно скрываем tableView чтобы избежать видимого "прыжка"
                    self.tableView.alpha = 0

                    self.tableView.reloadData()

                    // Принудительно делаем layout чтобы получить правильный contentSize
                    self.tableView.layoutIfNeeded()

                    // Настраиваем contentInset чтобы прижать сообщения к низу
                    self.adjustTableViewContentInset()

                    // Прокручиваем к последнему сообщению без анимации
                    if !self.messages.isEmpty {
                        let lastIndexPath = IndexPath(row: self.messages.count - 1, section: 0)
                        self.tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: false)
                    }

                    // Плавно показываем tableView
                    UIView.animate(withDuration: 0.2) {
                        self.tableView.alpha = 1
                    }

                    print("✅ Loaded \(self.messages.count) messages")
                    print("🔍 Current user ID: \(AuthManager.shared.currentUserId ?? -1)")

                    // Отладка: проверяем первые 3 сообщения
                    for (index, msg) in self.messages.prefix(3).enumerated() {
                        print("   Message \(index): senderId=\(msg.senderId), isIncoming=\(msg.isIncoming), content=\(msg.content?.prefix(20) ?? "nil")")
                    }
                }

                if let lastMessage = response.messages.first {
                    try? await APIService.shared.markChatAsRead(chatId: self.chat.id, lastMessageId: lastMessage.id)
                }
            } catch {
                print("❌ Failed to load messages: \(error)")
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
                print("📡 Got WebSocket subscription - token: \(subscription.token.prefix(20))..., channel: \(subscription.channel)")
                WebSocketService.shared.connect(subscription: subscription)
            } catch {
                print("❌ Failed to get WebSocket subscription: \(error)")
                // WebSocket не критичен для работы чата, продолжаем без него
                // Сообщения всё равно будут обновляться при отправке
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
        sendButton.setImage(nil, for: .normal)

        // Добавляем activity indicator на кнопку
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = DesignSystem.Colors.accentBlue
        activityIndicator.center = CGPoint(x: sendButton.bounds.width / 2, y: sendButton.bounds.height / 2)
        activityIndicator.startAnimating()
        sendButton.addSubview(activityIndicator)

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
                let response = try await APIService.shared.sendMessage(request: request)
                print("✅ Message sent successfully: \(response.messageId)")

                await MainActor.run {
                    // Удаляем activity indicator
                    self.sendButton.subviews.forEach { if $0 is UIActivityIndicatorView { $0.removeFromSuperview() } }
                    self.sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)

                    self.messageTextField.text = ""
                    self.messageTextField.isEnabled = true

                    // Обновляем состояние кнопки отправки
                    self.updateSendButtonState()

                    // Перезагружаем сообщения, чтобы показать отправленное
                    self.loadMessages()
                }
            } catch {
                print("❌ Failed to send message: \(error)")
                await MainActor.run {
                    // Удаляем activity indicator и восстанавливаем иконку
                    self.sendButton.subviews.forEach { if $0 is UIActivityIndicatorView { $0.removeFromSuperview() } }
                    self.sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)

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

    private func formatLastSeen(_ lastSeen: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: lastSeen) else {
            return "был(а) недавно"
        }

        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let days = components.day, days > 0 {
            if days == 1 {
                return "был(а) вчера"
            } else if days < 7 {
                return "был(а) \(days) дн. назад"
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd.MM.yyyy"
                return "был(а) \(dateFormatter.string(from: date))"
            }
        } else if let hours = components.hour, hours > 0 {
            return "был(а) \(hours) ч. назад"
        } else if let minutes = components.minute, minutes > 0 {
            return "был(а) \(minutes) мин. назад"
        } else {
            return "был(а) только что"
        }
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

        // Передаём avatarURL для входящих сообщений
        let senderAvatarURL = message.isIncoming ? (chat.avatarURL ?? chat.otherParticipant?.avatarURL) : nil

        cell.configure(with: message, senderAvatarURL: senderAvatarURL)
        return cell
    }
}

extension ChatViewController: WebSocketServiceDelegate {
    func webSocketDidConnect() {
        print("✅ WebSocket connected in ChatViewController for chat \(chat.id)")
    }

    func webSocketDidDisconnect(error: Error?) {
        print("❌ WebSocket disconnected in ChatViewController: \(error?.localizedDescription ?? "unknown")")
    }

    func webSocketDidReceiveMessage(_ message: Message) {
        print("📨 ChatViewController received message: ID=\(message.id), chatId=\(message.chatId ?? -1), currentChatId=\(chat.id)")

        // Если chatId не указан, или совпадает с текущим чатом
        let shouldAdd = message.chatId == nil || message.chatId == chat.id

        if shouldAdd {
            print("✅ Message belongs to current chat, adding to UI")
            print("   From: \(message.senderId), Content: \(message.content?.prefix(50) ?? "nil")")

            DispatchQueue.main.async {
                // Проверяем, что сообщение ещё не добавлено
                if !self.messages.contains(where: { $0.id == message.id }) {
                    // Добавляем сообщение в конец массива (список перевёрнут)
                    self.messages.append(message)
                    let newIndexPath = IndexPath(row: self.messages.count - 1, section: 0)
                    self.tableView.insertRows(at: [newIndexPath], with: .automatic)

                    // Прокручиваем к новому сообщению
                    self.tableView.scrollToRow(at: newIndexPath, at: .bottom, animated: true)
                    print("✅ Message added to table view successfully")
                } else {
                    print("⚠️ Message already exists in messages array, skipping")
                }
            }

            Task {
                try? await APIService.shared.markChatAsRead(chatId: self.chat.id, lastMessageId: message.id)
            }
        } else {
            print("⚠️ Message chatId (\(message.chatId ?? -1)) doesn't match current chat id (\(chat.id))")
        }
    }
}

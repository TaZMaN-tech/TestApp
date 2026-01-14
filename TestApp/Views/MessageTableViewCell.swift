//
//  MessageTableViewCell.swift
//  TestApp
//
//  Created by Claude on 12.01.2026.
//

import UIKit

class MessageTableViewCell: UITableViewCell {
    static let identifier = "MessageTableViewCell"

    private let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 18
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Fonts.body
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Fonts.footnote
        label.textColor = DesignSystem.Colors.secondaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.backgroundColor = DesignSystem.Colors.secondaryBackground
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    private var bubbleLeadingToAvatarConstraint: NSLayoutConstraint!
    private var bubbleLeadingToContentConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(avatarImageView)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        bubbleView.addSubview(timeLabel)

        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        bubbleLeadingToAvatarConstraint = bubbleView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 8)
        bubbleLeadingToContentConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8)

        NSLayoutConstraint.activate([
            // Avatar constraints (for incoming messages)
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            avatarImageView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 32),
            avatarImageView.heightAnchor.constraint(equalToConstant: 32),

            // Bubble constraints
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.7),

            // Message label constraints
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),

            // Time label constraints
            timeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 2),
            timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -6),
            timeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: bubbleView.leadingAnchor, constant: 12)
        ])
    }

    func configure(with message: Message, senderAvatarURL: String? = nil) {
        messageLabel.text = message.content

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: message.createdAt) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            timeLabel.text = timeFormatter.string(from: date)
        } else {
            timeLabel.text = ""
        }

        // Debug logging
        print("💬 Cell configure: msgId=\(message.id), senderId=\(message.senderId), currentUserId=\(AuthManager.shared.currentUserId ?? -1), isIncoming=\(message.isIncoming)")

        if message.isIncoming {
            // Входящее сообщение - слева с аватаром
            avatarImageView.isHidden = false
            bubbleLeadingToAvatarConstraint.isActive = true
            bubbleLeadingToContentConstraint.isActive = false
            trailingConstraint.isActive = false

            bubbleView.backgroundColor = DesignSystem.Colors.incomingMessageBackground
            messageLabel.textColor = DesignSystem.Colors.primaryText
            timeLabel.textColor = DesignSystem.Colors.secondaryText

            // Загружаем аватар
            if let avatarURL = senderAvatarURL, let url = URL(string: avatarURL) {
                loadAvatar(from: url)
            } else {
                avatarImageView.image = UIImage(systemName: "person.circle.fill")
                avatarImageView.tintColor = DesignSystem.Colors.secondaryText
            }
        } else {
            // Исходящее сообщение - справа без аватара
            avatarImageView.isHidden = true
            bubbleLeadingToAvatarConstraint.isActive = false
            bubbleLeadingToContentConstraint.isActive = false
            trailingConstraint.isActive = true

            bubbleView.backgroundColor = DesignSystem.Colors.outgoingMessageBackground
            messageLabel.textColor = .white
            timeLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        }
    }

    private func loadAvatar(from url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.avatarImageView.image = image
                    }
                }
            } catch {
                await MainActor.run {
                    self.avatarImageView.image = UIImage(systemName: "person.circle.fill")
                    self.avatarImageView.tintColor = DesignSystem.Colors.secondaryText
                }
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
        timeLabel.text = nil
        avatarImageView.image = nil
        avatarImageView.isHidden = true
    }
}

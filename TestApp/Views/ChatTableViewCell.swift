//
//  ChatTableViewCell.swift
//  TestApp
//
//  Created by Claude on 12.01.2026.
//

import UIKit

class ChatTableViewCell: UITableViewCell {
    static let identifier = "ChatTableViewCell"

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = DesignSystem.Sizes.avatarSmall / 2
        imageView.backgroundColor = DesignSystem.Colors.secondaryBackground
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Fonts.bodyBold
        label.textColor = DesignSystem.Colors.primaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Fonts.body
        label.textColor = DesignSystem.Colors.secondaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Fonts.caption
        label.textColor = DesignSystem.Colors.secondaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let unreadBadge: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Fonts.captionBold
        label.textColor = DesignSystem.Colors.primaryText
        label.backgroundColor = DesignSystem.Colors.accentBlue
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let onlineIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = DesignSystem.Colors.online
        view.layer.cornerRadius = 6
        view.layer.borderWidth = 2
        view.layer.borderColor = DesignSystem.Colors.primaryBackground.cgColor
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = DesignSystem.Colors.primaryBackground
        contentView.backgroundColor = DesignSystem.Colors.primaryBackground

        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(unreadBadge)
        contentView.addSubview(onlineIndicator)

        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DesignSystem.Spacing.large),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: DesignSystem.Sizes.avatarSmall),
            avatarImageView.heightAnchor.constraint(equalToConstant: DesignSystem.Sizes.avatarSmall),

            onlineIndicator.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
            onlineIndicator.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
            onlineIndicator.widthAnchor.constraint(equalToConstant: 12),
            onlineIndicator.heightAnchor.constraint(equalToConstant: 12),

            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: DesignSystem.Spacing.medium),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DesignSystem.Spacing.large),
            nameLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -DesignSystem.Spacing.small),

            messageLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: DesignSystem.Spacing.medium),
            messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: DesignSystem.Spacing.tiny),
            messageLabel.trailingAnchor.constraint(equalTo: unreadBadge.leadingAnchor, constant: -DesignSystem.Spacing.small),

            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DesignSystem.Spacing.large),
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DesignSystem.Spacing.large),
            timeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),

            unreadBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DesignSystem.Spacing.large),
            unreadBadge.centerYAnchor.constraint(equalTo: messageLabel.centerYAnchor),
            unreadBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            unreadBadge.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func configure(with chat: Chat) {
        nameLabel.text = chat.displayName

        if let lastMessage = chat.lastMessage {
            messageLabel.text = lastMessage.content ?? "Медиа"
        } else {
            messageLabel.text = "Нет сообщений"
        }

        if let unreadCount = chat.unreadCount, unreadCount > 0 {
            unreadBadge.isHidden = false
            unreadBadge.text = unreadCount > 99 ? "99+" : "\(unreadCount)"
        } else {
            unreadBadge.isHidden = true
        }

        if let updatedAt = chat.updatedAt {
            timeLabel.text = formatDate(updatedAt)
        } else {
            timeLabel.text = ""
        }

        if let participant = chat.otherParticipant, participant.isOnline == true {
            onlineIndicator.isHidden = false
        } else {
            onlineIndicator.isHidden = true
        }

        if let avatarURL = chat.avatar ?? chat.otherParticipant?.avatar,
           let url = URL(string: avatarURL) {
            loadImage(from: url)
        } else {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            avatarImageView.tintColor = .systemGray3
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: dateString) else {
            return ""
        }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Вчера"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yy"
            return dateFormatter.string(from: date)
        }
    }

    private func loadImage(from url: URL) {
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
                    self.avatarImageView.tintColor = .systemGray3
                }
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        nameLabel.text = nil
        messageLabel.text = nil
        timeLabel.text = nil
        unreadBadge.isHidden = true
        onlineIndicator.isHidden = true
    }
}

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
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!

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

        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        bubbleView.addSubview(timeLabel)

        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),

            timeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 4),
            timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
            timeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: bubbleView.leadingAnchor, constant: 12)
        ])
    }

    func configure(with message: Message) {
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

        if message.isIncoming {
            leadingConstraint.isActive = true
            trailingConstraint.isActive = false
            bubbleView.backgroundColor = .secondarySystemBackground
            messageLabel.textColor = .label
        } else {
            leadingConstraint.isActive = false
            trailingConstraint.isActive = true
            bubbleView.backgroundColor = .systemBlue
            messageLabel.textColor = .white
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
        timeLabel.text = nil
    }
}

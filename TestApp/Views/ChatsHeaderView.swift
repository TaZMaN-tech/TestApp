//
//  ChatsHeaderView.swift
//  TestApp
//
//  Created by Claude on 13.01.2026.
//

import UIKit

protocol ChatsHeaderViewDelegate: AnyObject {
    func chatsHeaderDidTapEdit()
    func chatsHeaderDidTapSearch()
    func chatsHeaderDidTapNewChat()
}

class ChatsHeaderView: UIView {

    weak var delegate: ChatsHeaderViewDelegate?

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.backgroundColor = DesignSystem.Colors.secondaryBackground
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = DesignSystem.Colors.secondaryText
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Fonts.title
        label.textColor = DesignSystem.Colors.primaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let chevronImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.down"))
        imageView.tintColor = DesignSystem.Colors.primaryText
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        button.tintColor = DesignSystem.Colors.primaryText
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        button.tintColor = DesignSystem.Colors.primaryText
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let newChatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        button.tintColor = DesignSystem.Colors.primaryText
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = DesignSystem.Colors.primaryBackground

        let userStack = UIStackView(arrangedSubviews: [avatarImageView, usernameLabel, chevronImageView])
        userStack.axis = .horizontal
        userStack.spacing = DesignSystem.Spacing.small
        userStack.alignment = .center
        userStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(userStack)
        addSubview(editButton)

        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),

            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12),

            userStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DesignSystem.Spacing.large),
            userStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            editButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DesignSystem.Spacing.large),
            editButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            editButton.widthAnchor.constraint(equalToConstant: 44),
            editButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupActions() {
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
    }

    @objc private func editButtonTapped() {
        delegate?.chatsHeaderDidTapEdit()
    }

    func configure(username: String, avatarURL: String?) {
        usernameLabel.text = username

        if let avatarURL = avatarURL, let url = URL(string: avatarURL) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        await MainActor.run {
                            self.avatarImageView.image = image
                        }
                    }
                } catch {
                    print("Failed to load avatar: \(error)")
                }
            }
        }
    }
}

//
//  NewChatViewController.swift
//  TestApp
//
//  Created by Claude on 13.01.2026.
//

import UIKit

class NewChatViewController: UIViewController {

    private var recommendedUsers: [User] = []

    private let searchTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Поиск"
        textField.font = DesignSystem.Fonts.body
        textField.textColor = DesignSystem.Colors.primaryText
        textField.backgroundColor = DesignSystem.Colors.secondaryBackground
        textField.layer.cornerRadius = DesignSystem.CornerRadius.small
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        textField.rightViewMode = .always
        textField.attributedPlaceholder = NSAttributedString(
            string: "Поиск",
            attributes: [.foregroundColor: DesignSystem.Colors.placeholderText]
        )
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let toLabel: UILabel = {
        let label = UILabel()
        label.text = "Кому:"
        label.font = DesignSystem.Fonts.body
        label.textColor = DesignSystem.Colors.primaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let recommendationsLabel: UILabel = {
        let label = UILabel()
        label.text = "Рекомендации"
        label.font = DesignSystem.Fonts.caption
        label.textColor = DesignSystem.Colors.secondaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.register(UserTableViewCell.self, forCellReuseIdentifier: "UserCell")
        table.rowHeight = 64
        table.separatorStyle = .singleLine
        table.backgroundColor = DesignSystem.Colors.primaryBackground
        table.separatorColor = DesignSystem.Colors.separator
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.color = DesignSystem.Colors.accentBlue
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadRecommendations()
    }

    private func setupUI() {
        title = "Новый чат"
        view.backgroundColor = DesignSystem.Colors.primaryBackground

        navigationController?.navigationBar.barTintColor = DesignSystem.Colors.primaryBackground
        navigationController?.navigationBar.backgroundColor = DesignSystem.Colors.primaryBackground
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: DesignSystem.Colors.primaryText,
            .font: DesignSystem.Fonts.title
        ]
        navigationController?.navigationBar.tintColor = DesignSystem.Colors.primaryText

        let cancelButton = UIBarButtonItem(title: "Отмена", style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.leftBarButtonItem = cancelButton

        let searchContainer = UIView()
        searchContainer.backgroundColor = DesignSystem.Colors.primaryBackground
        searchContainer.translatesAutoresizingMaskIntoConstraints = false

        searchContainer.addSubview(toLabel)
        searchContainer.addSubview(searchTextField)

        view.addSubview(searchContainer)
        view.addSubview(recommendationsLabel)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            searchContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchContainer.heightAnchor.constraint(equalToConstant: 60),

            toLabel.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: DesignSystem.Spacing.large),
            toLabel.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),

            searchTextField.leadingAnchor.constraint(equalTo: toLabel.trailingAnchor, constant: DesignSystem.Spacing.small),
            searchTextField.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -DesignSystem.Spacing.large),
            searchTextField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchTextField.heightAnchor.constraint(equalToConstant: 40),

            recommendationsLabel.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: DesignSystem.Spacing.medium),
            recommendationsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DesignSystem.Spacing.large),

            tableView.topAnchor.constraint(equalTo: recommendationsLabel.bottomAnchor, constant: DesignSystem.Spacing.small),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func searchTextChanged() {
        // TODO: Implement search
    }

    private func loadRecommendations() {
        activityIndicator.startAnimating()

        Task {
            do {
                // TODO: Get recommended users from API
                // Пока используем заглушку
                await MainActor.run {
                    self.recommendedUsers = []
                    self.activityIndicator.stopAnimating()
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension NewChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recommendedUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as? UserTableViewCell else {
            return UITableViewCell()
        }

        let user = recommendedUsers[indexPath.row]
        cell.configure(with: user)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = recommendedUsers[indexPath.row]

        // Создаём чат с этим пользователем
        createChat(withUser: user)
    }

    private func createChat(withUser user: User) {
        guard let username = user.username else {
            let alert = UIAlertController(title: "Ошибка", message: "У пользователя нет username", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        activityIndicator.startAnimating()

        Task {
            do {
                let chat = try await UserSearchHelper.createChatWithUsername(username)

                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.dismiss(animated: true) {
                        // TODO: Открыть созданный чат
                    }
                }
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    let alert = UIAlertController(title: "Ошибка", message: "Не удалось создать чат", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - UserTableViewCell
class UserTableViewCell: UITableViewCell {

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 24
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

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Fonts.caption
        label.textColor = DesignSystem.Colors.secondaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        contentView.addSubview(usernameLabel)

        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DesignSystem.Spacing.large),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 48),
            avatarImageView.heightAnchor.constraint(equalToConstant: 48),

            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: DesignSystem.Spacing.medium),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DesignSystem.Spacing.medium),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DesignSystem.Spacing.large),

            usernameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: DesignSystem.Spacing.medium),
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: DesignSystem.Spacing.tiny),
            usernameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DesignSystem.Spacing.large)
        ])
    }

    func configure(with user: User) {
        nameLabel.text = user.firstName ?? "Пользователь"
        usernameLabel.text = user.username.map { "@\($0)" } ?? ""

        if let avatarURL = user.avatar, let url = URL(string: avatarURL) {
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
        } else {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            avatarImageView.tintColor = DesignSystem.Colors.secondaryText
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        nameLabel.text = nil
        usernameLabel.text = nil
    }
}

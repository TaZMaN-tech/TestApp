//
//  ChatsViewController.swift
//  TestApp
//
//  Created by Claude on 12.01.2026.
//

import UIKit

class ChatsViewController: UIViewController {

    private var chats: [Chat] = []
    private var filteredChats: [Chat] = []
    private var isSearching = false

    private let searchController = UISearchController(searchResultsController: nil)

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.register(ChatTableViewCell.self, forCellReuseIdentifier: ChatTableViewCell.identifier)
        table.rowHeight = 80
        table.separatorStyle = .singleLine
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "Нет чатов"
        label.textColor = DesignSystem.Colors.secondaryText
        label.font = DesignSystem.Fonts.title
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let activityIndicatorStyle: UIActivityIndicatorView.Style = {
        return .large
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearchController()
        loadChats()
    }

    private func setupUI() {
        title = "Чаты"
        view.backgroundColor = DesignSystem.Colors.primaryBackground

        // Настройка navigation bar
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.barTintColor = DesignSystem.Colors.primaryBackground
        navigationController?.navigationBar.backgroundColor = DesignSystem.Colors.primaryBackground
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: DesignSystem.Colors.primaryText,
            .font: DesignSystem.Fonts.title
        ]

        // Настройка table view с цветами из дизайна
        tableView.backgroundColor = DesignSystem.Colors.primaryBackground
        tableView.separatorColor = DesignSystem.Colors.separator

        let searchUserButton = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"), style: .plain, target: self, action: #selector(searchUserTapped))
        let newChatButton = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(newChatTapped))
        searchUserButton.tintColor = DesignSystem.Colors.primaryText
        newChatButton.tintColor = DesignSystem.Colors.primaryText
        navigationItem.rightBarButtonItems = [newChatButton, searchUserButton]

        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск чатов"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func loadChats() {
        activityIndicator.startAnimating()
        emptyLabel.isHidden = true

        Task {
            do {
                let response = try await APIService.shared.getChats(limit: 100)

                await MainActor.run {
                    self.chats = response.chats
                    self.filteredChats = response.chats
                    self.activityIndicator.stopAnimating()
                    self.tableView.reloadData()

                    if self.chats.isEmpty {
                        self.emptyLabel.isHidden = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.showError(error)
                }
            }
        }
    }

    @objc private func newChatTapped() {
        // В будущем здесь будет переход на экран создания нового чата из Figma
        // Пока используем временное решение
        searchUserTapped()
    }

    @objc private func searchUserTapped() {
        let alert = UIAlertController(title: "Поиск пользователя", message: "Введите username пользователя", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Username"
            textField.autocapitalizationType = .none
            textField.text = "2/natfullin"
        }

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Найти", style: .default) { [weak self] _ in
            guard let username = alert.textFields?.first?.text, !username.isEmpty else { return }
            self?.searchForUser(username: username)
        })

        present(alert, animated: true)
    }

    private func searchForUser(username: String) {
        let loadingAlert = UIAlertController(title: "Поиск...", message: nil, preferredStyle: .alert)
        present(loadingAlert, animated: true)

        Task {
            do {
                if let existingChat = UserSearchHelper.findUserInChats(username: username, chats: self.chats) {
                    await MainActor.run {
                        loadingAlert.dismiss(animated: true) {
                            let chatVC = ChatViewController(chat: existingChat)
                            self.navigationController?.pushViewController(chatVC, animated: true)
                        }
                    }
                } else {
                    let chat = try await UserSearchHelper.createChatWithUsername(username)

                    await MainActor.run {
                        self.chats.insert(chat, at: 0)
                        self.filteredChats = self.chats
                        self.tableView.reloadData()

                        loadingAlert.dismiss(animated: true) {
                            let chatVC = ChatViewController(chat: chat)
                            self.navigationController?.pushViewController(chatVC, animated: true)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        let errorAlert = UIAlertController(title: "Ошибка", message: "Пользователь не найден или не удалось создать чат", preferredStyle: .alert)
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(errorAlert, animated: true)
                    }
                }
            }
        }
    }

    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "Выход", message: "Вы уверены что хотите выйти?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Выйти", style: .destructive) { [weak self] _ in
            self?.logout()
        })
        present(alert, animated: true)
    }

    private func logout() {
        AuthManager.shared.clearTokens()

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let authVC = AuthViewController()
            window.rootViewController = authVC
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {})
        }
    }

    private func showError(_ error: Error) {
        let message: String
        if case let APIError.serverError(serverMessage) = error {
            message = serverMessage
        } else {
            message = "Не удалось загрузить чаты"
        }

        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            self?.loadChats()
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
}

extension ChatsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredChats.count : chats.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatTableViewCell.identifier, for: indexPath) as? ChatTableViewCell else {
            return UITableViewCell()
        }

        let chat = isSearching ? filteredChats[indexPath.row] : chats[indexPath.row]
        cell.configure(with: chat)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let chat = isSearching ? filteredChats[indexPath.row] : chats[indexPath.row]
        let chatVC = ChatViewController(chat: chat)
        navigationController?.pushViewController(chatVC, animated: true)
    }
}

extension ChatsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            isSearching = false
            filteredChats = chats
            tableView.reloadData()
            return
        }

        isSearching = true
        filteredChats = chats.filter { chat in
            chat.displayName.lowercased().contains(searchText.lowercased())
        }
        tableView.reloadData()
    }
}

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
    private var currentTab: ChatsTab = .messages

    private let headerView = ChatsHeaderView()
    private let tabsView = ChatsTabsView()
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
        view.backgroundColor = DesignSystem.Colors.primaryBackground

        // Скрываем стандартный navigation bar
        navigationController?.setNavigationBarHidden(true, animated: false)

        // Настройка table view с цветами из дизайна
        tableView.backgroundColor = DesignSystem.Colors.primaryBackground
        tableView.separatorColor = DesignSystem.Colors.separator

        // Настройка header и tabs
        headerView.delegate = self
        headerView.translatesAutoresizingMaskIntoConstraints = false

        tabsView.delegate = self
        tabsView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerView)
        view.addSubview(tabsView)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),

            tabsView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tabsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabsView.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: tabsView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Загружаем данные пользователя для header
        loadCurrentUser()
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск чатов"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func loadCurrentUser() {
        Task {
            do {
                let currentUser: User = try await APIService.shared.request(endpoint: "/users/me", method: "GET")
                await MainActor.run {
                    let username = currentUser.username ?? currentUser.firstName ?? "Пользователь"
                    self.headerView.configure(username: username, avatarURL: currentUser.avatar)
                }
            } catch {
                print("❌ Ошибка загрузки данных пользователя: \(error)")
            }
        }
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
        let newChatVC = NewChatViewController()
        let navController = UINavigationController(rootViewController: newChatVC)
        present(navController, animated: true)
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

// MARK: - ChatsHeaderViewDelegate
extension ChatsViewController: ChatsHeaderViewDelegate {
    func chatsHeaderDidTapEdit() {
        let alert = UIAlertController(title: "Меню", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Профиль", style: .default))
        alert.addAction(UIAlertAction(title: "Настройки", style: .default))
        alert.addAction(UIAlertAction(title: "Выйти", style: .destructive) { [weak self] _ in
            self?.logout()
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    func chatsHeaderDidTapSearch() {
        searchUserTapped()
    }

    func chatsHeaderDidTapNewChat() {
        newChatTapped()
    }
}

// MARK: - ChatsTabsViewDelegate
extension ChatsViewController: ChatsTabsViewDelegate {
    func chatsTabsViewDidSelectTab(_ tab: ChatsTab) {
        currentTab = tab
        // TODO: Фильтровать чаты по табу (архив/обычные)
        tableView.reloadData()
    }
}

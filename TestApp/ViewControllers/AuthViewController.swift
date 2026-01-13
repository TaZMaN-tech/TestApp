//
//  AuthViewController.swift
//  TestApp
//
//  Created by Claude on 12.01.2026.
//

import UIKit

class AuthViewController: UIViewController {

    private let authWebSocket = AuthWebSocketService()
    private var currentSessionId: String?

    // Иконка логотипа (заглушка - будет синяя звезда с иконками)
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // TODO: Добавить настоящую иконку из Figma
        imageView.backgroundColor = DesignSystem.Colors.accentBlue
        imageView.layer.cornerRadius = 100
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Вход в учетную запись"
        label.font = DesignSystem.Fonts.systemFont(size: 28, weight: .bold)
        label.textAlignment = .center
        label.textColor = DesignSystem.Colors.primaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Вход в приложение осуществляется\nчерез аккаунт в Telegram"
        label.font = DesignSystem.Fonts.body
        label.textAlignment = .center
        label.textColor = DesignSystem.Colors.secondaryText
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Войти в приложение", for: .normal)
        button.backgroundColor = DesignSystem.Colors.accentBlue
        button.setTitleColor(DesignSystem.Colors.primaryText, for: .normal)
        button.titleLabel?.font = DesignSystem.Fonts.systemFont(size: 17, weight: .semibold)
        button.layer.cornerRadius = DesignSystem.CornerRadius.medium
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Зарегистрироваться", for: .normal)
        button.backgroundColor = DesignSystem.Colors.secondaryBackground
        button.setTitleColor(DesignSystem.Colors.primaryText, for: .normal)
        button.titleLabel?.font = DesignSystem.Fonts.systemFont(size: 17, weight: .semibold)
        button.layer.cornerRadius = DesignSystem.CornerRadius.medium
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let disclaimerLabel: UILabel = {
        let label = UILabel()
        label.text = "При входе или регистрации вы соглашаетесь\nс нашей Политикой использования"
        label.font = DesignSystem.Fonts.footnote
        label.textAlignment = .center
        label.textColor = DesignSystem.Colors.secondaryText
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        setupActions()
        checkAuthentication()
    }

    private func setupUI() {
        view.backgroundColor = DesignSystem.Colors.primaryBackground

        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(loginButton)
        view.addSubview(registerButton)
        view.addSubview(disclaimerLabel)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            logoImageView.widthAnchor.constraint(equalToConstant: 200),
            logoImageView.heightAnchor.constraint(equalToConstant: 200),

            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DesignSystem.Spacing.huge),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DesignSystem.Spacing.huge),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: DesignSystem.Spacing.medium),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DesignSystem.Spacing.huge),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DesignSystem.Spacing.huge),

            loginButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DesignSystem.Spacing.large),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DesignSystem.Spacing.large),
            loginButton.heightAnchor.constraint(equalToConstant: 56),

            registerButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: DesignSystem.Spacing.medium),
            registerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DesignSystem.Spacing.large),
            registerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DesignSystem.Spacing.large),
            registerButton.heightAnchor.constraint(equalToConstant: 56),

            disclaimerLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -DesignSystem.Spacing.large),
            disclaimerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DesignSystem.Spacing.huge),
            disclaimerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DesignSystem.Spacing.huge),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupActions() {
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
    }

    @objc private func loginButtonTapped() {
        startAuthFlow()
    }

    @objc private func registerButtonTapped() {
        // Регистрация - тот же флоу что и вход
        startAuthFlow()
    }

    private func checkAuthentication() {
        if AuthManager.shared.isAuthenticated {
            navigateToChats()
        }
    }

    private func startAuthFlow() {
        activityIndicator.startAnimating()
        loginButton.isEnabled = false
        registerButton.isEnabled = false

        authWebSocket.delegate = self

        Task {
            do {
                // Сначала проверим, есть ли уже анонимная сессия
                var sessionId: String

                if let existingSessionId = AuthManager.shared.anonymousSessionId {
                    sessionId = existingSessionId
                    print("📱 Используем существующую сессию: \(sessionId)")
                } else {
                    // Создаём новую анонимную сессию
                    let session = try await APIService.shared.createSession()
                    sessionId = session.id

                    // Сохраняем анонимную сессию
                    AuthManager.shared.saveAnonymousSession(session)
                    print("📱 Создана новая сессия: \(sessionId)")
                }

                currentSessionId = sessionId

                // Получаем базовый URL бота от API
                let baseBotURL = try await APIService.shared.getBotURL(sessionId: sessionId)
                print("📱 Базовый URL бота: \(baseBotURL)")

                // Добавляем параметр start с session_id
                let fullBotURL = "\(baseBotURL)?start=\(sessionId)"
                print("📱 Полный URL бота с session_id: \(fullBotURL)")

                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.loginButton.isEnabled = true
                    self.registerButton.isEnabled = true
                    self.openTelegramBotWithURL(fullBotURL)
                    self.connectWebSocket(sessionId: sessionId)
                }
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.loginButton.isEnabled = true
                    self.registerButton.isEnabled = true
                    self.showAlert(message: "Ошибка: \(error.localizedDescription)")
                }
            }
        }
    }

    private func openTelegramBotWithURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url) { success in
                if !success {
                    DispatchQueue.main.async {
                        self.showAlert(message: "Не удалось открыть Telegram. Убедитесь, что приложение установлено.")
                    }
                }
            }
        }
    }

    private func connectWebSocket(sessionId: String) {
        authWebSocket.connect(sessionId: sessionId)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func navigateToChats() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let chatsVC = ChatsViewController()
            let navController = UINavigationController(rootViewController: chatsVC)
            window.rootViewController = navController
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {})
        }
    }
}

// MARK: - AuthWebSocketDelegate
extension AuthViewController: AuthWebSocketDelegate {
    func authWebSocketDidConnect() {
        print("✅ WebSocket подключен, ожидание токенов...")
    }

    func authWebSocketDidReceiveTokens(accessToken: String, refreshToken: String) {
        print("✅ Получены токены авторизации")

        Task {
            do {
                // Сохраняем токены временно, чтобы сделать запрос
                let tokens = TokenInfo(accessToken: accessToken, refreshToken: refreshToken, tokenType: "Bearer")
                AuthManager.shared.saveTokens(tokens, userId: 0) // Временный userId

                // Получаем информацию о текущем пользователе
                let currentUser: User = try await APIService.shared.getCurrentUser()

                await MainActor.run {
                    // Теперь сохраняем токены с правильным userId
                    AuthManager.shared.saveTokens(tokens, userId: currentUser.id)
                    self.navigateToChats()
                }
            } catch {
                await MainActor.run {
                    self.showAlert(message: "Ошибка получения данных пользователя: \(error.localizedDescription)")
                }
            }
        }
    }

    func authWebSocketDidFailWithError(_ error: Error) {
        DispatchQueue.main.async {
            self.showAlert(message: "Ошибка WebSocket: \(error.localizedDescription)")
        }
    }
}

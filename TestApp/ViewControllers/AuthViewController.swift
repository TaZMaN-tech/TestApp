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

    private let logoLabel: UILabel = {
        let label = UILabel()
        label.text = "Интересно и точка"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Войдите через Telegram бота"
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let openTelegramButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Открыть Telegram", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 12
        button.isEnabled = false
        button.alpha = 0.5
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let orLabel: UILabel = {
        let label = UILabel()
        label.text = "или отсканируйте QR-код"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let qrCodeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Ожидание подключения..."
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let manualTokenButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Ввести токен вручную", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        checkAuthentication()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(logoLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(openTelegramButton)
        view.addSubview(orLabel)
        view.addSubview(qrCodeImageView)
        view.addSubview(statusLabel)
        view.addSubview(activityIndicator)
        view.addSubview(manualTokenButton)

        NSLayoutConstraint.activate([
            logoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -250),
            logoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            logoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            subtitleLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            openTelegramButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            openTelegramButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            openTelegramButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            openTelegramButton.heightAnchor.constraint(equalToConstant: 54),

            orLabel.topAnchor.constraint(equalTo: openTelegramButton.bottomAnchor, constant: 24),
            orLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            qrCodeImageView.topAnchor.constraint(equalTo: orLabel.bottomAnchor, constant: 16),
            qrCodeImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            qrCodeImageView.widthAnchor.constraint(equalToConstant: 200),
            qrCodeImageView.heightAnchor.constraint(equalToConstant: 200),

            statusLabel.topAnchor.constraint(equalTo: qrCodeImageView.bottomAnchor, constant: 24),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            activityIndicator.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            manualTokenButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            manualTokenButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupActions() {
        openTelegramButton.addTarget(self, action: #selector(openTelegramButtonTapped), for: .touchUpInside)
        manualTokenButton.addTarget(self, action: #selector(manualTokenButtonTapped), for: .touchUpInside)
    }

    @objc private func openTelegramButtonTapped() {
        guard let sessionId = currentSessionId else {
            showAlert(message: "Сессия еще не создана. Подождите...")
            return
        }

        let botURL = "https://t.me/interesnoitochka_bot?start=auth_\(sessionId)"

        if let url = URL(string: botURL) {
            UIApplication.shared.open(url) { success in
                if !success {
                    DispatchQueue.main.async {
                        self.showAlert(message: "Не удалось открыть Telegram. Используйте QR-код.")
                    }
                }
            }
        }
    }

    private func checkAuthentication() {
        if AuthManager.shared.isAuthenticated {
            navigateToChats()
        } else {
            startAuthFlow()
        }
    }

    private func startAuthFlow() {
        activityIndicator.startAnimating()
        statusLabel.text = "Создание сессии..."

        authWebSocket.delegate = self

        Task {
            do {
                let session = try await APIService.shared.createSession()
                currentSessionId = session.id

                await MainActor.run {
                    self.generateQRCode(sessionId: session.id)
                    self.connectWebSocket(sessionId: session.id)
                }
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.statusLabel.text = "Ошибка создания сессии"
                    self.showAlert(message: "Не удалось создать сессию: \(error.localizedDescription)")
                }
            }
        }
    }

    private func generateQRCode(sessionId: String) {
        let qrString = "https://t.me/interesnoitochka_bot?start=auth_\(sessionId)"

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return }
        let data = qrString.data(using: .ascii)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else { return }

        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: transform)

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return }

        qrCodeImageView.image = UIImage(cgImage: cgImage)
    }

    private func connectWebSocket(sessionId: String) {
        statusLabel.text = "Подключение к серверу..."
        authWebSocket.connect(sessionId: sessionId)
    }

    @objc private func manualTokenButtonTapped() {
        let alert = UIAlertController(title: "Ввод токена", message: "Введите access token", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Access Token"
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        alert.addTextField { textField in
            textField.placeholder = "Refresh Token"
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Войти", style: .default) { [weak self] _ in
            guard let accessToken = alert.textFields?[0].text, !accessToken.isEmpty,
                  let refreshToken = alert.textFields?[1].text, !refreshToken.isEmpty else {
                return
            }

            let tokens = TokenInfo(accessToken: accessToken, refreshToken: refreshToken, tokenType: "Bearer")
            AuthManager.shared.saveTokens(tokens, userId: 0)
            self?.navigateToChats()
        })

        present(alert, animated: true)
    }

    private func navigateToChats() {
        let chatsVC = ChatsViewController()
        let navController = UINavigationController(rootViewController: chatsVC)
        navController.modalPresentationStyle = .fullScreen

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = navController
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {})
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    deinit {
        authWebSocket.disconnect()
    }
}

extension AuthViewController: AuthWebSocketDelegate {
    func authWebSocketDidConnect() {
        statusLabel.text = "Нажмите кнопку выше или отсканируйте QR-код"
        activityIndicator.stopAnimating()
        openTelegramButton.isEnabled = true
        openTelegramButton.alpha = 1.0
    }

    func authWebSocketDidReceiveTokens(accessToken: String, refreshToken: String) {
        authWebSocket.disconnect()

        let tokens = TokenInfo(accessToken: accessToken, refreshToken: refreshToken, tokenType: "Bearer")
        AuthManager.shared.saveTokens(tokens, userId: 0)

        statusLabel.text = "Успешно! Переход к чатам..."

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.navigateToChats()
        }
    }

    func authWebSocketDidFailWithError(_ error: Error) {
        activityIndicator.stopAnimating()
        statusLabel.text = "Ошибка подключения"
        showAlert(message: "Ошибка WebSocket: \(error.localizedDescription)")
    }
}

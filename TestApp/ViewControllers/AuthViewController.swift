//
//  AuthViewController.swift
//  TestApp
//
//  Created by Claude on 12.01.2026.
//

import UIKit

class AuthViewController: UIViewController {

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
        label.text = "Войдите чтобы продолжить"
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Имя пользователя"
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.backgroundColor = .secondarySystemBackground
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray4.cgColor
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Войти", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
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
        view.backgroundColor = .systemBackground

        view.addSubview(logoLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(usernameTextField)
        view.addSubview(loginButton)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            logoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -150),
            logoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            logoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            subtitleLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            usernameTextField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 48),
            usernameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            usernameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            usernameTextField.heightAnchor.constraint(equalToConstant: 54),

            loginButton.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 24),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            loginButton.heightAnchor.constraint(equalToConstant: 54),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16)
        ])
    }

    private func setupActions() {
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        usernameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    private func checkAuthentication() {
        if AuthManager.shared.isAuthenticated {
            navigateToChats()
        }
    }

    @objc private func textFieldDidChange() {
        loginButton.isEnabled = !(usernameTextField.text?.isEmpty ?? true)
        loginButton.alpha = loginButton.isEnabled ? 1.0 : 0.5
    }

    @objc private func loginButtonTapped() {
        guard let username = usernameTextField.text, !username.isEmpty else {
            showAlert(message: "Пожалуйста введите имя пользователя")
            return
        }

        login(username: username)
    }

    private func login(username: String) {
        loginButton.isEnabled = false
        usernameTextField.isEnabled = false
        activityIndicator.startAnimating()

        Task {
            do {
                let response = try await APIService.shared.login(username: username)
                AuthManager.shared.saveTokens(response.tokens, userId: response.user.id)

                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.navigateToChats()
                }
            } catch {
                await MainActor.run {
                    self.activityIndicator.stopAnimating()
                    self.loginButton.isEnabled = true
                    self.usernameTextField.isEnabled = true

                    let errorMessage: String
                    if case let APIError.serverError(message) = error {
                        errorMessage = message
                    } else {
                        errorMessage = "Не удалось войти. Проверьте имя пользователя."
                    }

                    self.showAlert(message: errorMessage)
                }
            }
        }
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
}

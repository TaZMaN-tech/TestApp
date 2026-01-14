//
//  ChatActionsBottomSheet.swift
//  TestApp
//
//  Created by Тадевос Курдоглян on 13.01.2026.
//

import UIKit

protocol ChatActionsBottomSheetDelegate: AnyObject {
    func didSelectArchive(chat: Chat)
    func didSelectPin(chat: Chat)
    func didSelectDelete(chat: Chat)
    func didSelectMute(chat: Chat)
}

class ChatActionsBottomSheet: UIViewController {

    weak var delegate: ChatActionsBottomSheetDelegate?
    private let chat: Chat

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = DesignSystem.Colors.secondaryBackground
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let handleView: UIView = {
        let view = UIView()
        view.backgroundColor = DesignSystem.Colors.tertiaryText
        view.layer.cornerRadius = 2.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    init(chat: Chat) {
        self.chat = chat
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        view.addSubview(containerView)
        containerView.addSubview(handleView)
        containerView.addSubview(stackView)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            handleView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            handleView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 36),
            handleView.heightAnchor.constraint(equalToConstant: 5),

            stackView.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        addActionButton(title: "Архивировать", iconName: "archivebox", action: #selector(archiveTapped))
        addActionButton(title: "Закрепить", iconName: "pin", action: #selector(pinTapped))
        addActionButton(title: "Выключить уведомления", iconName: "bell.slash", action: #selector(muteTapped))
        addSeparator()
        addActionButton(title: "Удалить чат", iconName: "trash", action: #selector(deleteTapped), destructive: true)
    }

    private func addActionButton(title: String, iconName: String, action: Selector, destructive: Bool = false) {
        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .left

        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: iconName)
        config.imagePadding = 16
        config.imagePlacement = .leading
        config.title = title
        config.baseForegroundColor = destructive ? .systemRed : .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)

        button.configuration = config
        button.addTarget(self, action: action, for: .touchUpInside)

        stackView.addArrangedSubview(button)
    }

    private func addSeparator() {
        let separator = UIView()
        separator.backgroundColor = DesignSystem.Colors.primaryBackground
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stackView.addArrangedSubview(separator)
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissSheet))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(panGesture)
    }

    @objc private func dismissSheet() {
        dismiss(animated: true)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        if translation.y > 0 {
            containerView.transform = CGAffineTransform(translationX: 0, y: translation.y)
        }

        if gesture.state == .ended {
            if translation.y > 100 {
                dismiss(animated: true)
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.containerView.transform = .identity
                }
            }
        }
    }

    @objc private func archiveTapped() {
        dismiss(animated: true) {
            self.delegate?.didSelectArchive(chat: self.chat)
        }
    }

    @objc private func pinTapped() {
        dismiss(animated: true) {
            self.delegate?.didSelectPin(chat: self.chat)
        }
    }

    @objc private func muteTapped() {
        dismiss(animated: true) {
            self.delegate?.didSelectMute(chat: self.chat)
        }
    }

    @objc private func deleteTapped() {
        dismiss(animated: true) {
            self.delegate?.didSelectDelete(chat: self.chat)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Анимация появления
        containerView.transform = CGAffineTransform(translationX: 0, y: containerView.frame.height)
        UIView.animate(withDuration: 0.3) {
            self.containerView.transform = .identity
        }
    }
}

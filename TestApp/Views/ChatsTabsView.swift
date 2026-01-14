//
//  ChatsTabsView.swift
//  TestApp
//
//  Created by Claude on 13.01.2026.
//

import UIKit

protocol ChatsTabsViewDelegate: AnyObject {
    func chatsTabsViewDidSelectTab(_ tab: ChatsTab)
}

// ChatsTab enum is defined in ChatsViewModel.swift

class ChatsTabsView: UIView {

    weak var delegate: ChatsTabsViewDelegate?
    private var selectedTab: ChatsTab = .messages

    private let messagesButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Сообщения", for: .normal)
        button.titleLabel?.font = DesignSystem.Fonts.bodyBold
        button.tag = 0
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let archiveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Архив", for: .normal)
        button.titleLabel?.font = DesignSystem.Fonts.body
        button.tag = 1
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let underlineView: UIView = {
        let view = UIView()
        view.backgroundColor = DesignSystem.Colors.accentBlue
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var underlineLeadingConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
        updateTabAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = DesignSystem.Colors.primaryBackground

        let stackView = UIStackView(arrangedSubviews: [messagesButton, archiveButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)
        addSubview(underlineView)

        underlineLeadingConstraint = underlineView.leadingAnchor.constraint(equalTo: messagesButton.leadingAnchor)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            underlineView.heightAnchor.constraint(equalToConstant: 2),
            underlineView.bottomAnchor.constraint(equalTo: bottomAnchor),
            underlineView.widthAnchor.constraint(equalTo: messagesButton.widthAnchor),
            underlineLeadingConstraint
        ])
    }

    private func setupActions() {
        messagesButton.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        archiveButton.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
    }

    @objc private func tabButtonTapped(_ sender: UIButton) {
        selectedTab = sender.tag == 0 ? .messages : .archive
        updateTabAppearance()
        delegate?.chatsTabsViewDidSelectTab(selectedTab)
    }

    private func updateTabAppearance() {
        messagesButton.setTitleColor(
            selectedTab == .messages ? DesignSystem.Colors.primaryText : DesignSystem.Colors.secondaryText,
            for: .normal
        )
        messagesButton.titleLabel?.font = selectedTab == .messages ? DesignSystem.Fonts.bodyBold : DesignSystem.Fonts.body

        archiveButton.setTitleColor(
            selectedTab == .archive ? DesignSystem.Colors.primaryText : DesignSystem.Colors.secondaryText,
            for: .normal
        )
        archiveButton.titleLabel?.font = selectedTab == .archive ? DesignSystem.Fonts.bodyBold : DesignSystem.Fonts.body

        UIView.animate(withDuration: 0.3) {
            self.underlineLeadingConstraint.isActive = false
            self.underlineLeadingConstraint = self.underlineView.leadingAnchor.constraint(
                equalTo: self.selectedTab == .messages ? self.messagesButton.leadingAnchor : self.archiveButton.leadingAnchor
            )
            self.underlineLeadingConstraint.isActive = true
            self.layoutIfNeeded()
        }
    }
}

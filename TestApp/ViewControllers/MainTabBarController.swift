//
//  MainTabBarController.swift
//  TestApp
//
//  Created by Тадевос Курдоглян on 13.01.2026.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
    }

    private func setupTabBar() {
        tabBar.backgroundColor = DesignSystem.Colors.primaryBackground
        tabBar.barTintColor = DesignSystem.Colors.primaryBackground
        tabBar.tintColor = DesignSystem.Colors.accentBlue
        tabBar.unselectedItemTintColor = DesignSystem.Colors.secondaryText

        // Убираем верхнюю линию
        tabBar.shadowImage = UIImage()
        tabBar.backgroundImage = UIImage()

        // Добавляем кастомную верхнюю линию
        let lineView = UIView(frame: CGRect(x: 0, y: 0, width: tabBar.frame.width, height: 0.5))
        lineView.backgroundColor = DesignSystem.Colors.secondaryBackground
        tabBar.addSubview(lineView)
    }

    private func setupViewControllers() {
        // 1. Чаты
        let chatsVC = ChatsViewController()
        let chatsNav = UINavigationController(rootViewController: chatsVC)
        chatsNav.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "message"),
            selectedImage: UIImage(systemName: "message.fill")
        )

        // 2. Контакты (placeholder)
        let contactsVC = UIViewController()
        contactsVC.view.backgroundColor = DesignSystem.Colors.primaryBackground
        let contactsNav = UINavigationController(rootViewController: contactsVC)
        contactsNav.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "person.2"),
            selectedImage: UIImage(systemName: "person.2.fill")
        )

        // 3. Настройки (placeholder)
        let settingsVC = UIViewController()
        settingsVC.view.backgroundColor = DesignSystem.Colors.primaryBackground
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )

        // 4. Профиль (placeholder)
        let profileVC = UIViewController()
        profileVC.view.backgroundColor = DesignSystem.Colors.primaryBackground
        let profileNav = UINavigationController(rootViewController: profileVC)
        profileNav.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(systemName: "person.crop.circle"),
            selectedImage: UIImage(systemName: "person.crop.circle.fill")
        )

        viewControllers = [chatsNav, contactsNav, settingsNav, profileNav]
    }
}

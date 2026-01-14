//
//  OnboardingViewController.swift
//  TestApp
//
//  Created by Тадевос Курдоглян on 13.01.2026.
//

import UIKit

class OnboardingViewController: UIViewController {

    private var currentPage = 0
    private let totalPages = 4

    private let pages: [(title: String, description: String, imageName: String)] = [
        (
            title: "Смотрите ваших блогеров",
            description: "Тут какое-то описание в пару строчек\nкак классно можно делать что-то",
            imageName: "onboarding1"
        ),
        (
            title: "Общайтесь с друзьями",
            description: "Тут какое-то описание в пару строчек\nкак классно можно делать что-то",
            imageName: "onboarding2"
        ),
        (
            title: "Делайте покупки в маркете",
            description: "Тут какое-то описание в пару строчек\nкак классно можно делать что-то",
            imageName: "onboarding3"
        ),
        (
            title: "Участвуйте в акциях",
            description: "Тут какое-то описание в пару строчек\nкак классно можно делать что-то",
            imageName: "onboarding4"
        )
    ]

    // UI Elements
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = 4
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = DesignSystem.Colors.secondaryText.withAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Fonts.systemFont(size: 24, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Fonts.body
        label.textAlignment = .center
        label.textColor = DesignSystem.Colors.secondaryText
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Далее", for: .normal)
        button.backgroundColor = DesignSystem.Colors.accentBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = DesignSystem.Fonts.systemFont(size: 17, weight: .semibold)
        button.layer.cornerRadius = DesignSystem.CornerRadius.medium
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Пропустить", for: .normal)
        button.backgroundColor = DesignSystem.Colors.secondaryBackground
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = DesignSystem.Fonts.systemFont(size: 17, weight: .semibold)
        button.layer.cornerRadius = DesignSystem.CornerRadius.medium
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        updateContent()
    }

    private func setupUI() {
        view.backgroundColor = DesignSystem.Colors.primaryBackground

        scrollView.delegate = self

        view.addSubview(scrollView)
        view.addSubview(pageControl)
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(nextButton)
        view.addSubview(skipButton)

        // Setup scroll view content
        let contentStackView = UIStackView()
        contentStackView.axis = .horizontal
        contentStackView.distribution = .fillEqually
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)

        // Add pages
        var pageConstraints: [NSLayoutConstraint] = []
        for i in 0..<totalPages {
            let pageView = createPageView(for: i)
            contentStackView.addArrangedSubview(pageView)
            // Каждая страница должна быть равна ширине view
            pageConstraints.append(pageView.widthAnchor.constraint(equalTo: view.widthAnchor))
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 400),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            pageControl.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: DesignSystem.Spacing.medium),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            titleLabel.topAnchor.constraint(equalTo: pageControl.bottomAnchor, constant: DesignSystem.Spacing.large),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DesignSystem.Spacing.huge),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DesignSystem.Spacing.huge),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: DesignSystem.Spacing.medium),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DesignSystem.Spacing.huge),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DesignSystem.Spacing.huge),

            nextButton.bottomAnchor.constraint(equalTo: skipButton.topAnchor, constant: -DesignSystem.Spacing.medium),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DesignSystem.Spacing.large),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DesignSystem.Spacing.large),
            nextButton.heightAnchor.constraint(equalToConstant: 56),

            skipButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -DesignSystem.Spacing.large),
            skipButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DesignSystem.Spacing.large),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DesignSystem.Spacing.large),
            skipButton.heightAnchor.constraint(equalToConstant: 56)
        ])

        // Активируем constraints для ширины страниц
        NSLayoutConstraint.activate(pageConstraints)
    }

    private func createPageView(for index: Int) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: pages[index].imageName)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            imageView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.8),

            containerView.widthAnchor.constraint(equalTo: containerView.heightAnchor)
        ])

        return containerView
    }

    private func setupActions() {
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
    }

    @objc private func nextButtonTapped() {
        if currentPage < totalPages - 1 {
            currentPage += 1
            let offset = CGPoint(x: scrollView.frame.width * CGFloat(currentPage), y: 0)
            scrollView.setContentOffset(offset, animated: true)
            updateContent()
        } else {
            finishOnboarding()
        }
    }

    @objc private func skipButtonTapped() {
        finishOnboarding()
    }

    private func updateContent() {
        let page = pages[currentPage]
        titleLabel.text = page.title
        descriptionLabel.text = page.description
        pageControl.currentPage = currentPage

        if currentPage == totalPages - 1 {
            nextButton.setTitle("Начать", for: .normal)
        } else {
            nextButton.setTitle("Далее", for: .normal)
        }
    }

    private func finishOnboarding() {
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        // Navigate to auth screen
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let authVC = AuthViewController()
            window.rootViewController = authVC
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {})
        }
    }
}

// MARK: - UIScrollViewDelegate
extension OnboardingViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x / scrollView.frame.width)
        currentPage = Int(pageIndex)
        updateContent()
    }
}

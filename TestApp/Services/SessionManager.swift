//
//  SessionManager.swift
//  TestApp
//
//  Created by Тадевос Курдоглян on 13.01.2026.
//

import Foundation

/// Менеджер для управления анонимными сессиями
class SessionManager {
    static let shared = SessionManager()

    private init() {}

    /// Инициализирует анонимную сессию при первом запуске приложения
    func initializeAnonymousSessionIfNeeded() async {
        // Если пользователь уже авторизован, ничего не делаем
        if AuthManager.shared.isAuthenticated {
            return
        }

        // Если уже есть активная анонимная сессия, ничего не делаем
        if AuthManager.shared.hasAnonymousSession {
            return
        }

        // Создаём новую анонимную сессию
        do {
            let session = try await APIService.shared.createSession()
            AuthManager.shared.saveAnonymousSession(session)
            print("✅ Анонимная сессия создана: \(session.id)")
        } catch {
            print("❌ Ошибка создания анонимной сессии: \(error)")
        }
    }

    /// Обновляет анонимную сессию, если она истекла
    func refreshAnonymousSessionIfExpired() async {
        // Если пользователь авторизован, анонимная сессия не нужна
        if AuthManager.shared.isAuthenticated {
            return
        }

        // Если анонимная сессия истекла или её нет
        if !AuthManager.shared.hasAnonymousSession {
            await initializeAnonymousSessionIfNeeded()
        }
    }
}

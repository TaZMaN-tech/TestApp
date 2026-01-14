//
//  DateFormatter+Extensions.swift
//  TestApp
//
//  Created by Тадевос Курдоглян on 2026-01-14.
//

import Foundation

extension DateFormatter {

    /// Format message timestamp based on how old it is
    /// - Today: "HH:mm" (e.g., "14:30")
    /// - Yesterday: "Вчера HH:mm"
    /// - This week: "Day HH:mm" (e.g., "Пн 14:30")
    /// - Older: "dd.MM.yyyy HH:mm"
    static func formatMessageTime(_ dateString: String) -> String {
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = iso8601Formatter.date(from: dateString) else {
            return ""
        }

        let calendar = Calendar.current
        let now = Date()

        // Check if today
        if calendar.isDateInToday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.string(from: date)
        }

        // Check if yesterday
        if calendar.isDateInYesterday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return "Вчера \(timeFormatter.string(from: date))"
        }

        // Check if within last 7 days
        let components = calendar.dateComponents([.day], from: date, to: now)
        if let days = components.day, days < 7 {
            let timeFormatter = DateFormatter()
            timeFormatter.locale = Locale(identifier: "ru_RU")
            timeFormatter.dateFormat = "E HH:mm"
            return timeFormatter.string(from: date)
        }

        // Older than 7 days
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        return timeFormatter.string(from: date)
    }

    /// Format chat last message timestamp
    /// - Less than 1 hour: "X мин. назад"
    /// - Today: "HH:mm"
    /// - Yesterday: "Вчера"
    /// - This week: "Day"
    /// - Older: "dd.MM.yyyy"
    static func formatChatTimestamp(_ dateString: String) -> String {
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = iso8601Formatter.date(from: dateString) else {
            return ""
        }

        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)

        // Less than 1 hour ago
        if let minutes = components.minute, let hours = components.hour, hours == 0, minutes < 60 {
            if minutes == 0 {
                return "Только что"
            }
            return "\(minutes) мин. назад"
        }

        // Today
        if calendar.isDateInToday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.string(from: date)
        }

        // Yesterday
        if calendar.isDateInYesterday(date) {
            return "Вчера"
        }

        // Within last 7 days
        if let days = components.day, days < 7 {
            let timeFormatter = DateFormatter()
            timeFormatter.locale = Locale(identifier: "ru_RU")
            timeFormatter.dateFormat = "EEEE"
            return timeFormatter.string(from: date)
        }

        // Older
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "dd.MM.yyyy"
        return timeFormatter.string(from: date)
    }
}

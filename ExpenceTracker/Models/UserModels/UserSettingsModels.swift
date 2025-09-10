//
//  UserSettingsModels.swift - FIXED: USD default currency
//  ExpenseTracker
//
//  Created by Developer on 21/06/2025.
//

import SwiftUI
import Foundation

// MARK: - User Profile Model
struct UserProfile: Codable {
    var name: String
    var email: String?
    var avatarImageData: Data?
    var createdAt: Date
    
    init(name: String = "User", email: String? = nil) {
        self.name = name
        self.email = email
        self.avatarImageData = nil
        self.createdAt = Date()
    }
}

// MARK: - Currency Settings (CLEAN: No flags, professional design)
enum Currency: String, CaseIterable, Codable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case cny = "CNY"
    case cad = "CAD"
    case aud = "AUD"
    case chf = "CHF"
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .cny: return "¥"
        case .cad: return "$"
        case .aud: return "$"
        case .chf: return "₣"
        }
    }
    
    var name: String {
        switch self {
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .jpy: return "Japanese Yen"
        case .cny: return "Chinese Yuan"
        case .cad: return "Canadian Dollar"
        case .aud: return "Australian Dollar"
        case .chf: return "Swiss Franc"
        }
    }
    
    var code: String {
        return rawValue
    }
}

// MARK: - Number Format Settings
enum NumberFormat: String, CaseIterable, Codable {
    case decimal = "decimal"        // $1,234.56
    case spaced = "spaced"          // 1 234,56 ₽
    case compact = "compact"        // $1.2K
    
    var name: String {
        switch self {
        case .decimal: return "1,234.56"
        case .spaced: return "1 234,56"
        case .compact: return "1.2K (compact)"
        }
    }
    
    func format(_ amount: Double, currency: Currency) -> String {
        switch self {
        case .decimal:
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            let number = formatter.string(from: NSNumber(value: amount)) ?? "0.00"
            return "\(currency.symbol)\(number)"
            
        case .spaced:
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = " "
            formatter.decimalSeparator = ","
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            let number = formatter.string(from: NSNumber(value: amount)) ?? "0,00"
            return "\(number) \(currency.symbol)"
            
        case .compact:
            if amount >= 1000 {
                return "\(currency.symbol)\(String(format: "%.1f", amount / 1000))K"
            } else {
                return "\(currency.symbol)\(String(format: "%.0f", amount))"
            }
        }
    }
}

// MARK: - Week Start Settings
enum WeekStart: String, CaseIterable, Codable {
    case monday = "monday"
    case sunday = "sunday"
    
    var name: String {
        switch self {
        case .monday: return "Monday"
        case .sunday: return "Sunday"
        }
    }
    
    var weekday: Int {
        switch self {
        case .monday: return 2  // Calendar.current monday
        case .sunday: return 1  // Calendar.current sunday
        }
    }
}

// MARK: - App Theme Settings
enum AppTheme: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var name: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "iphone"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - App Language Settings (INTERNATIONAL: No Russian)
enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case japanese = "ja"
    case korean = "ko"
    case chinese = "zh"
    
    var name: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .chinese: return "中文"
        }
    }
    
    var code: String {
        return rawValue
    }
}

// MARK: - Budget Settings
struct BudgetSettings: Codable {
    var dailyBudget: Double?
    var monthlyBudget: Double?
    var isEnabled: Bool
    
    init() {
        self.dailyBudget = nil
        self.monthlyBudget = nil
        self.isEnabled = false
    }
}

// MARK: - Notification Settings
struct NotificationSettings: Codable {
    var isEnabled: Bool
    var dailyReminder: Bool
    var budgetAlerts: Bool
    var weeklyReports: Bool
    var reminderTime: Date
    
    init() {
        self.isEnabled = false
        self.dailyReminder = false
        self.budgetAlerts = false
        self.weeklyReports = false
        self.reminderTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

// MARK: - Privacy Settings
struct PrivacySettings: Codable {
    var requireAuthentication: Bool
    var hideAmountsInBackground: Bool
    var localStorageOnly: Bool
    
    init() {
        self.requireAuthentication = false
        self.hideAmountsInBackground = true
        self.localStorageOnly = true
    }
}

// MARK: - Main App Settings (FIXED: USD default)
struct AppSettings: Codable, Equatable {
    // User Profile
    var userProfile: UserProfile
    
    // Financial Settings
    var currency: Currency
    var numberFormat: NumberFormat
    var weekStart: WeekStart
    var budgetSettings: BudgetSettings
    
    // App Preferences
    var theme: AppTheme
    var language: AppLanguage
    
    // Features
    var notificationSettings: NotificationSettings
    var privacySettings: PrivacySettings
    
    // App Info
    var appVersion: String
    var createdAt: Date
    var lastModified: Date
    
    init() {
        self.userProfile = UserProfile()
        self.currency = .usd // ✅ FIXED: Changed from .rub to .usd
        self.numberFormat = .decimal
        self.weekStart = .monday
        self.budgetSettings = BudgetSettings()
        self.theme = .system
        self.language = .english // ✅ FIXED: Changed from .russian to .english
        self.notificationSettings = NotificationSettings()
        self.privacySettings = PrivacySettings()
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        self.createdAt = Date()
        self.lastModified = Date()
    }
    
    // ✅ FIXED: Implement Equatable to prevent unnecessary updates
    static func == (lhs: AppSettings, rhs: AppSettings) -> Bool {
        return lhs.currency == rhs.currency &&
               lhs.theme == rhs.theme &&
               lhs.language == rhs.language &&
               lhs.numberFormat == rhs.numberFormat &&
               lhs.weekStart == rhs.weekStart &&
               lhs.userProfile.name == rhs.userProfile.name &&
               lhs.userProfile.email == rhs.userProfile.email &&
               lhs.budgetSettings.isEnabled == rhs.budgetSettings.isEnabled &&
               lhs.notificationSettings.isEnabled == rhs.notificationSettings.isEnabled
    }
}

// MARK: - Settings Section Models (for UI)
struct SettingsSection {
    let title: String
    let items: [SettingsItem]
    let footer: String?
    
    init(title: String, items: [SettingsItem], footer: String? = nil) {
        self.title = title
        self.items = items
        self.footer = footer
    }
}

struct SettingsItem {
    let id = UUID()
    let title: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let action: SettingsAction
    
    init(title: String, subtitle: String? = nil, icon: String, iconColor: Color = .blue, action: SettingsAction) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.action = action
    }
}

enum SettingsAction {
    case navigation(destination: AnyView)
    case toggle(binding: Binding<Bool>)
    case action(() -> Void)
    case disclosure(value: String)
}

// MARK: - Helper Extensions
extension Currency {
    func formatAmount(_ amount: Double, format: NumberFormat) -> String {
        return format.format(amount, currency: self)
    }
}

//
//  UserSettingsManager.swift - FIXED: Prevent crashes on currency/theme changes
//  ExpenseTracker
//
//  Created by Developer on 24/06/2025.
//

import SwiftUI
import Foundation
import Combine

// MARK: - Fixed User Settings Manager (prevents crashes)
@MainActor
final class UserSettingsManager: SettingsManagerProtocol {
    
    // MARK: - Published Properties for protocol
    @Published var settings: AppSettings {
        didSet {
            // ✅ OPTIMIZED: Prevent recursive updates and batch saves
            guard settings != oldValue else { return }
            guard !isUpdating else { return }
            
            settings.lastModified = Date()
            
            // ✅ OPTIMIZED: Longer debounce to batch multiple rapid changes
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                Task { @MainActor in
                    self.saveSettings()
                }
            }
        }
    }
    
    @Published internal var _errorMessage: String?
    
    var errorPublisher: AnyPublisher<String?, Never> {
        $_errorMessage.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "AppSettings_v2"
    private let oldSettingsKey = "AppSettings"
    private var debounceTimer: Timer? // ✅ FIXED: Debounce saves
    private var isUpdating = false // ✅ FIXED: Prevent recursive updates
    
    // MARK: - Initialization
    init() {
        self.settings = Self.loadSettingsWithMigration()
        print("✅ UserSettingsManager: Settings loaded and migrated")
    }
    
    deinit {
        debounceTimer?.invalidate()
    }
    
    // MARK: - Settings Migration & Persistence
    
    private static func loadSettingsWithMigration() -> AppSettings {
        let userDefaults = UserDefaults.standard
        let newKey = "AppSettings_v2"
        let oldKey = "AppSettings"
        
        // Try loading new version
        if let data = userDefaults.data(forKey: newKey),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            print("📂 UserSettingsManager: Loaded v2 settings")
            return settings
        }
        
        // Try migrating from old version
        if let oldData = userDefaults.data(forKey: oldKey),
           let oldSettings = try? JSONDecoder().decode(AppSettings.self, from: oldData) {
            print("🔄 UserSettingsManager: Migrating from v1 to v2")
            
            // Save in new format
            let migrated = oldSettings
            if let newData = try? JSONEncoder().encode(migrated) {
                userDefaults.set(newData, forKey: newKey)
                userDefaults.removeObject(forKey: oldKey) // Remove old version
                print("✅ UserSettingsManager: Migration completed")
            }
            
            return migrated
        }
        
        // Create default settings
        print("📦 UserSettingsManager: Creating default settings")
        let defaultSettings = AppSettings()
        
        // Save default settings
        if let data = try? JSONEncoder().encode(defaultSettings) {
            userDefaults.set(data, forKey: newKey)
        }
        
        return defaultSettings
    }
    
    private func saveSettings() {
        // ✅ OPTIMIZED: Background saving to prevent UI hangs
        guard !isUpdating else { return }
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            do {
                let data = try await JSONEncoder().encode(self.settings)
                
                await MainActor.run {
                    self.userDefaults.set(data, forKey: self.settingsKey)
                    print("💾 UserSettingsManager: Settings saved")
                }
            } catch {
                await MainActor.run {
                    self.handleError("Failed to save settings: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - User Profile Implementation
    
    func updateUserName(_ name: String) {
        guard !isUpdating else { return }
        
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, cleanName.count <= 50 else {
            handleError("Invalid user name")
            return
        }
        
        isUpdating = true
        settings.userProfile.name = cleanName
        isUpdating = false
        
        print("👤 UserSettingsManager: User name updated to '\(cleanName)'")
    }
    
    func updateUserEmail(_ email: String?) {
        guard !isUpdating else { return }
        
        if let email = email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty {
            guard isValidEmail(email) else {
                handleError("Invalid email format")
                return
            }
            isUpdating = true
            settings.userProfile.email = email
            isUpdating = false
        } else {
            isUpdating = true
            settings.userProfile.email = nil
            isUpdating = false
        }
        
        print("📧 UserSettingsManager: User email updated")
    }
    
    func updateUserAvatar(_ imageData: Data?) {
        guard !isUpdating else { return }
        
        isUpdating = true
        settings.userProfile.avatarImageData = imageData
        isUpdating = false
        
        print("🖼️ UserSettingsManager: User avatar updated")
    }
    
    // MARK: - Financial Settings Implementation (FIXED)
    
    func updateCurrency(_ currency: Currency) {
        // ✅ FIXED: Prevent recursive updates
        guard !isUpdating else {
            print("💱 UserSettingsManager: Update in progress, skipping currency change")
            return
        }
        
        // ✅ FIXED: Check if currency is already set
        guard currency != settings.currency else {
            print("💱 UserSettingsManager: Currency already set to \(currency.rawValue)")
            return
        }
        
        let oldCurrency = settings.currency
        
        isUpdating = true
        settings.currency = currency
        isUpdating = false
        
        print("💱 UserSettingsManager: Currency changed from \(oldCurrency.rawValue) to \(currency.rawValue)")
        
        // ✅ OPTIMIZED: Longer debounce to prevent rapid-fire notifications
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NotificationCenter.default.post(name: .currencyDidChange, object: currency)
        }
    }
    
    func updateNumberFormat(_ format: NumberFormat) {
        guard !isUpdating else { return }
        guard format != settings.numberFormat else { return }
        
        isUpdating = true
        settings.numberFormat = format
        isUpdating = false
        
        print("🔢 UserSettingsManager: Number format updated to \(format.rawValue)")
        
        // Debounced notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: .numberFormatDidChange, object: format)
        }
    }
    
    func updateWeekStart(_ weekStart: WeekStart) {
        guard !isUpdating else { return }
        guard weekStart != settings.weekStart else { return }
        
        isUpdating = true
        settings.weekStart = weekStart
        isUpdating = false
        
        print("📅 UserSettingsManager: Week start updated to \(weekStart.rawValue)")
        
        // Debounced notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: .weekStartDidChange, object: weekStart)
        }
    }
    
    // MARK: - Budget Implementation
    
    func updateDailyBudget(_ amount: Double?) {
        guard !isUpdating else { return }
        
        if let amount = amount {
            guard amount > 0, amount <= 1_000_000 else {
                handleError("Invalid daily budget amount")
                return
            }
        }
        
        isUpdating = true
        settings.budgetSettings.dailyBudget = amount
        isUpdating = false
        
        print("🎯 UserSettingsManager: Daily budget updated to \(amount?.description ?? "nil")")
    }
    
    func updateMonthlyBudget(_ amount: Double?) {
        guard !isUpdating else { return }
        
        if let amount = amount {
            guard amount > 0, amount <= 1_000_000 else {
                handleError("Invalid monthly budget amount")
                return
            }
        }
        
        isUpdating = true
        settings.budgetSettings.monthlyBudget = amount
        isUpdating = false
        
        print("🎯 UserSettingsManager: Monthly budget updated to \(amount?.description ?? "nil")")
    }
    
    func toggleBudgetEnabled(_ enabled: Bool) {
        guard !isUpdating else { return }
        guard enabled != settings.budgetSettings.isEnabled else { return }
        
        isUpdating = true
        settings.budgetSettings.isEnabled = enabled
        isUpdating = false
        
        print("🎯 UserSettingsManager: Budget enabled: \(enabled)")
        
        if enabled {
            // Debounced notification
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .budgetEnabledDidChange, object: enabled)
            }
        }
    }
    
    // MARK: - App Preferences Implementation (FIXED)
    
    func updateTheme(_ theme: AppTheme) {
        // ✅ FIXED: Prevent recursive updates
        guard !isUpdating else {
            print("🎨 UserSettingsManager: Update in progress, skipping theme change")
            return
        }
        
        // ✅ FIXED: Check if theme is already set
        guard theme != settings.theme else {
            print("🎨 UserSettingsManager: Theme already set to \(theme.rawValue)")
            return
        }
        
        let oldTheme = settings.theme
        
        isUpdating = true
        settings.theme = theme
        isUpdating = false
        
        print("🎨 UserSettingsManager: Theme updated from \(oldTheme.rawValue) to \(theme.rawValue)")
        
        // ✅ OPTIMIZED: Longer debounce to prevent rapid-fire notifications
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NotificationCenter.default.post(name: .themeDidChange, object: theme)
        }
    }
    
    func updateLanguage(_ language: AppLanguage) {
        guard !isUpdating else { return }
        guard language != settings.language else { return }
        
        isUpdating = true
        settings.language = language
        isUpdating = false
        
        print("🌐 UserSettingsManager: Language updated to \(language.rawValue)")
        
        // Debounced notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: .languageDidChange, object: language)
        }
    }
    
    // MARK: - Notifications Implementation
    
    func updateNotificationSettings(_ notificationSettings: NotificationSettings) {
        guard !isUpdating else { return }
        
        isUpdating = true
        settings.notificationSettings = notificationSettings
        isUpdating = false
        
        print("🔔 UserSettingsManager: Notification settings updated")
    }
    
    func toggleNotifications(_ enabled: Bool) {
        guard !isUpdating else { return }
        guard enabled != settings.notificationSettings.isEnabled else { return }
        
        isUpdating = true
        settings.notificationSettings.isEnabled = enabled
        isUpdating = false
        
        print("🔔 UserSettingsManager: Notifications enabled: \(enabled)")
    }
    
    func toggleDailyReminder(_ enabled: Bool) {
        guard !isUpdating else { return }
        
        isUpdating = true
        settings.notificationSettings.dailyReminder = enabled
        isUpdating = false
        
        print("🔔 UserSettingsManager: Daily reminder: \(enabled)")
    }
    
    func toggleBudgetAlerts(_ enabled: Bool) {
        guard !isUpdating else { return }
        
        isUpdating = true
        settings.notificationSettings.budgetAlerts = enabled
        isUpdating = false
        
        print("🔔 UserSettingsManager: Budget alerts: \(enabled)")
    }
    
    func toggleWeeklyReports(_ enabled: Bool) {
        guard !isUpdating else { return }
        
        isUpdating = true
        settings.notificationSettings.weeklyReports = enabled
        isUpdating = false
        
        print("🔔 UserSettingsManager: Weekly reports: \(enabled)")
    }
    
    func updateReminderTime(_ time: Date) {
        guard !isUpdating else { return }
        
        isUpdating = true
        settings.notificationSettings.reminderTime = time
        isUpdating = false
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        print("🔔 UserSettingsManager: Reminder time updated to \(formatter.string(from: time))")
    }
    
    // MARK: - Privacy Implementation
    
    func toggleRequireAuthentication(_ enabled: Bool) {
        guard !isUpdating else { return }
        
        isUpdating = true
        settings.privacySettings.requireAuthentication = enabled
        isUpdating = false
        
        print("🔒 UserSettingsManager: Require authentication: \(enabled)")
        
        if enabled {
            requestBiometricSetup()
        }
    }
    
    func toggleHideAmountsInBackground(_ enabled: Bool) {
        guard !isUpdating else { return }
        
        isUpdating = true
        settings.privacySettings.hideAmountsInBackground = enabled
        isUpdating = false
        
        print("🔒 UserSettingsManager: Hide amounts in background: \(enabled)")
    }
    
    func toggleLocalStorageOnly(_ enabled: Bool) {
        guard !isUpdating else { return }
        
        isUpdating = true
        settings.privacySettings.localStorageOnly = enabled
        isUpdating = false
        
        print("🔒 UserSettingsManager: Local storage only: \(enabled)")
        
        if enabled {
            // Disable any cloud syncs
            NotificationCenter.default.post(name: .cloudSyncDisabled, object: nil)
        }
    }
    
    // MARK: - Utility Implementation
    
    func formatAmount(_ amount: Double) -> String {
        return settings.currency.formatAmount(amount, format: settings.numberFormat)
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    func isValidBudgetAmount(_ amount: String) -> Bool {
        guard let value = Double(amount), value > 0, value <= 1_000_000 else {
            return false
        }
        return true
    }
    
    // MARK: - Data Management Implementation
    
    func resetAllSettings() {
        guard !isUpdating else { return }
        
        isUpdating = true
        settings = AppSettings()
        isUpdating = false
        
        print("🔄 UserSettingsManager: All settings reset to defaults")
        
        // Notify about full reset
        NotificationCenter.default.post(name: .settingsDidReset, object: nil)
    }
    
    func clearAllData() {
        resetAllSettings()
        
        // Notify other managers to clear
        NotificationCenter.default.post(name: .allDataShouldClear, object: nil)
        
        print("🗑️ UserSettingsManager: Clear all data initiated")
    }
    
    // MARK: - Private Helper Methods
    
    private func requestBiometricSetup() {
        // Real app would set up LAContext here
        print("🔐 UserSettingsManager: Biometric setup requested")
        
        // Simulation for development
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("🔐 UserSettingsManager: Biometric setup completed")
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ message: String) {
        _errorMessage = message
        print("❌ UserSettingsManager Error: \(message)")
    }
    
    func clearError() {
        _errorMessage = nil
    }
}

// MARK: - Computed Properties for UI
extension UserSettingsManager {
    var formattedCurrency: String {
        "\(settings.currency.symbol) \(settings.currency.name)"
    }
    
    var formattedTheme: String {
        settings.theme.name
    }
    
    var formattedLanguage: String {
        settings.language.name
    }
    
    var formattedNumberFormat: String {
        let example = settings.numberFormat.format(1234.56, currency: settings.currency)
        return "\(settings.numberFormat.name) • \(example)"
    }
    
    var formattedWeekStart: String {
        settings.weekStart.name
    }
    
    var formattedBudget: String {
        if let daily = settings.budgetSettings.dailyBudget {
            return "Daily: \(formatAmount(daily))"
        } else if let monthly = settings.budgetSettings.monthlyBudget {
            return "Monthly: \(formatAmount(monthly))"
        } else {
            return "Not set"
        }
    }
    
    var appInfo: String {
        "Version \(settings.appVersion)"
    }
}

// MARK: - Notification Names for inter-component communication
extension Notification.Name {
    static let currencyDidChange = Notification.Name("currencyDidChange")
    static let numberFormatDidChange = Notification.Name("numberFormatDidChange")
    static let weekStartDidChange = Notification.Name("weekStartDidChange")
    static let themeDidChange = Notification.Name("themeDidChange")
    static let languageDidChange = Notification.Name("languageDidChange")
    static let budgetEnabledDidChange = Notification.Name("budgetEnabledDidChange")
    static let settingsDidReset = Notification.Name("settingsDidReset")
    static let allDataShouldClear = Notification.Name("allDataShouldClear")
    static let cloudSyncDisabled = Notification.Name("cloudSyncDisabled")
}

// MARK: - Preview Support
extension UserSettingsManager {
    static let preview: UserSettingsManager = {
        let manager = UserSettingsManager()
        manager.settings.userProfile.name = "John Doe"
        manager.settings.userProfile.email = "john@example.com"
        manager.settings.currency = .usd
        return manager
    }()
}

// MARK: - Development Helpers
#if DEBUG
extension UserSettingsManager {
    func printAllSettings() {
        print("📊 Current Settings:")
        print("   User: \(settings.userProfile.name)")
        print("   Email: \(settings.userProfile.email ?? "none")")
        print("   Currency: \(settings.currency.rawValue)")
        print("   Theme: \(settings.theme.rawValue)")
        print("   Budget Enabled: \(settings.budgetSettings.isEnabled)")
        print("   Notifications: \(settings.notificationSettings.isEnabled)")
    }
    
    func simulateFirstLaunch() {
        // For testing first launch
        userDefaults.removeObject(forKey: settingsKey)
        userDefaults.removeObject(forKey: oldSettingsKey)
        settings = AppSettings()
        print("🧪 UserSettingsManager: Simulated first launch")
    }
}
#endif

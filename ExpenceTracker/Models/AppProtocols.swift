//
//  AppProtocols.swift
//  ExpenseTracker
//
//  Created by Developer on 24/06/2025.
//

import SwiftUI
import Combine

// MARK: - Core Data Manager Protocol
protocol CoreDataManagerProtocol: ObservableObject {
    var errorPublisher: AnyPublisher<String?, Never> { get }
    
    // Categories
    func loadCategories() async throws -> [Category]
    func addCategory(name: String, icon: String, color: Color) async -> Bool
    func updateCategory(_ category: Category, name: String?, icon: String?, color: Color?) async -> Bool
    func deleteCategory(_ category: Category) async -> Bool
    func reorderCategories(_ categories: [Category]) async -> Bool
    
    // Expenses
    func loadRecentExpenses(limit: Int) async throws -> [Expense]
    func addExpense(amount: Double, name: String, notes: String?, category: Category, date: Date) async -> Bool
    func deleteExpense(_ expense: Expense) async -> Bool
    func getExpensesForDate(_ date: Date) async -> [Expense]
    func getTotalForDate(_ date: Date) async -> Double
    func getTotalForCurrentMonth() async -> Double
    func getCategorySpendingForDate(_ date: Date) async -> [UUID: Double]
    
    // Analytics
    func getCategoryExpenseCount(_ category: Category) async -> Int
    func getCategoryTotalAmount(_ category: Category) async -> Double
    func searchExpenses(query: String) async -> [Expense]
}

// MARK: - Settings Manager Protocol
protocol SettingsManagerProtocol: ObservableObject {
    var settings: AppSettings { get }
    var errorPublisher: AnyPublisher<String?, Never> { get }
    
    // User Profile
    func updateUserName(_ name: String)
    func updateUserEmail(_ email: String?)
    func updateUserAvatar(_ imageData: Data?)
    
    // Financial Settings
    func updateCurrency(_ currency: Currency)
    func updateNumberFormat(_ format: NumberFormat)
    func updateWeekStart(_ weekStart: WeekStart)
    
    // Budget
    func updateDailyBudget(_ amount: Double?)
    func updateMonthlyBudget(_ amount: Double?)
    func toggleBudgetEnabled(_ enabled: Bool)
    
    // App Preferences
    func updateTheme(_ theme: AppTheme)
    func updateLanguage(_ language: AppLanguage)
    
    // Notifications
    func updateNotificationSettings(_ settings: NotificationSettings)
    func toggleNotifications(_ enabled: Bool)
    func toggleDailyReminder(_ enabled: Bool)
    func toggleBudgetAlerts(_ enabled: Bool)
    func toggleWeeklyReports(_ enabled: Bool)
    func updateReminderTime(_ time: Date)
    
    // Privacy
    func toggleRequireAuthentication(_ enabled: Bool)
    func toggleHideAmountsInBackground(_ enabled: Bool)
    func toggleLocalStorageOnly(_ enabled: Bool)
    
    // Utility
    func formatAmount(_ amount: Double) -> String
    func isValidEmail(_ email: String) -> Bool
    func isValidBudgetAmount(_ amount: String) -> Bool
    
    // Data Management
    func resetAllSettings()
    func clearAllData()
}

// MARK: - Notification Manager Protocol
protocol NotificationManagerProtocol: ObservableObject {
    var authorizationStatus: UNAuthorizationStatus { get }
    var scheduledNotifications: [UNNotificationRequest] { get }
    var errorPublisher: AnyPublisher<String?, Never> { get }
    
    func requestNotificationPermission() async -> Bool
    func updateSettings(_ settings: NotificationSettings) async
    func configureFromSettings(_ settings: NotificationSettings) async
    func sendImmediateNotification(title: String, body: String) async
    func cancelAllNotifications() async
    func updateScheduledNotifications() async
}

// MARK: - Mock Implementations для Preview и тестов

// MARK: - Mock Core Data Manager
class MockCoreDataManager: CoreDataManagerProtocol {
    @Published var errorMessage: String? = nil
    
    var errorPublisher: AnyPublisher<String?, Never> {
        $errorMessage.eraseToAnyPublisher()
    }
    
    func loadCategories() async throws -> [Category] {
        // Возвращаем mock категории для preview
        return []
    }
    
    func addCategory(name: String, icon: String, color: Color) async -> Bool {
        return true
    }
    
    func updateCategory(_ category: Category, name: String?, icon: String?, color: Color?) async -> Bool {
        return true
    }
    
    func deleteCategory(_ category: Category) async -> Bool {
        return true
    }
    
    func reorderCategories(_ categories: [Category]) async -> Bool {
        return true
    }
    
    func loadRecentExpenses(limit: Int) async throws -> [Expense] {
        return []
    }
    
    func addExpense(amount: Double, name: String, notes: String?, category: Category, date: Date) async -> Bool {
        return true
    }
    
    func deleteExpense(_ expense: Expense) async -> Bool {
        return true
    }
    
    func getExpensesForDate(_ date: Date) async -> [Expense] {
        return []
    }
    
    func getTotalForDate(_ date: Date) async -> Double {
        return 0
    }
    
    func getTotalForCurrentMonth() async -> Double {
        return 0
    }
    
    func getCategorySpendingForDate(_ date: Date) async -> [UUID: Double] {
        return [:]
    }
    
    func getCategoryExpenseCount(_ category: Category) async -> Int {
        return 0
    }
    
    func getCategoryTotalAmount(_ category: Category) async -> Double {
        return 0
    }
    
    func searchExpenses(query: String) async -> [Expense] {
        return []
    }
}

// MARK: - Mock Settings Manager
class MockSettingsManager: SettingsManagerProtocol {
    @Published var settings = AppSettings()
    @Published var errorMessage: String? = nil
    
    var errorPublisher: AnyPublisher<String?, Never> {
        $errorMessage.eraseToAnyPublisher()
    }
    
    func updateUserName(_ name: String) {
        settings.userProfile.name = name
    }
    
    func updateUserEmail(_ email: String?) {
        settings.userProfile.email = email
    }
    
    func updateUserAvatar(_ imageData: Data?) {
        settings.userProfile.avatarImageData = imageData
    }
    
    func updateCurrency(_ currency: Currency) {
        settings.currency = currency
    }
    
    func updateNumberFormat(_ format: NumberFormat) {
        settings.numberFormat = format
    }
    
    func updateWeekStart(_ weekStart: WeekStart) {
        settings.weekStart = weekStart
    }
    
    func updateDailyBudget(_ amount: Double?) {
        settings.budgetSettings.dailyBudget = amount
    }
    
    func updateMonthlyBudget(_ amount: Double?) {
        settings.budgetSettings.monthlyBudget = amount
    }
    
    func toggleBudgetEnabled(_ enabled: Bool) {
        settings.budgetSettings.isEnabled = enabled
    }
    
    func updateTheme(_ theme: AppTheme) {
        settings.theme = theme
    }
    
    func updateLanguage(_ language: AppLanguage) {
        settings.language = language
    }
    
    func updateNotificationSettings(_ settings: NotificationSettings) {
        self.settings.notificationSettings = settings
    }
    
    func toggleNotifications(_ enabled: Bool) {
        settings.notificationSettings.isEnabled = enabled
    }
    
    func toggleDailyReminder(_ enabled: Bool) {
        settings.notificationSettings.dailyReminder = enabled
    }
    
    func toggleBudgetAlerts(_ enabled: Bool) {
        settings.notificationSettings.budgetAlerts = enabled
    }
    
    func toggleWeeklyReports(_ enabled: Bool) {
        settings.notificationSettings.weeklyReports = enabled
    }
    
    func updateReminderTime(_ time: Date) {
        settings.notificationSettings.reminderTime = time
    }
    
    func toggleRequireAuthentication(_ enabled: Bool) {
        settings.privacySettings.requireAuthentication = enabled
    }
    
    func toggleHideAmountsInBackground(_ enabled: Bool) {
        settings.privacySettings.hideAmountsInBackground = enabled
    }
    
    func toggleLocalStorageOnly(_ enabled: Bool) {
        settings.privacySettings.localStorageOnly = enabled
    }
    
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
    
    func resetAllSettings() {
        settings = AppSettings()
    }
    
    func clearAllData() {
        resetAllSettings()
    }
}

// MARK: - Mock Notification Manager
class MockNotificationManager: NotificationManagerProtocol {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var scheduledNotifications: [UNNotificationRequest] = []
    @Published var errorMessage: String? = nil
    
    var errorPublisher: AnyPublisher<String?, Never> {
        $errorMessage.eraseToAnyPublisher()
    }
    
    func requestNotificationPermission() async -> Bool {
        authorizationStatus = .authorized
        return true
    }
    
    func updateSettings(_ settings: NotificationSettings) async {
        // Mock implementation
    }
    
    func configureFromSettings(_ settings: NotificationSettings) async {
        // Mock implementation
    }
    
    func sendImmediateNotification(title: String, body: String) async {
        // Mock implementation
    }
    
    func cancelAllNotifications() async {
        scheduledNotifications.removeAll()
    }
    
    func updateScheduledNotifications() async {
        // Mock implementation
    }
}

// MARK: - Extensions для UNAuthorizationStatus
extension UNAuthorizationStatus {
    var isAuthorized: Bool {
        return self == .authorized || self == .provisional
    }
    
    var description: String {
        switch self {
        case .notDetermined:
            return "Не определен"
        case .denied:
            return "Запрещены"
        case .authorized:
            return "Разрешены"
        case .provisional:
            return "Временно разрешены"
        case .ephemeral:
            return "Временные"
        @unknown default:
            return "Неизвестно"
        }
    }
}

// MARK: - Реальная реализация NotificationManager (заглушка)
class NotificationManager: NotificationManagerProtocol {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var scheduledNotifications: [UNNotificationRequest] = []
    @Published var errorMessage: String? = nil
    
    var errorPublisher: AnyPublisher<String?, Never> {
        $errorMessage.eraseToAnyPublisher()
    }
    
    init() {
        checkAuthorizationStatus()
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.authorizationStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            await MainActor.run {
                self.errorMessage = "Ошибка запроса разрешений: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    func updateSettings(_ settings: NotificationSettings) async {
        // TODO: Реальная реализация
        print("📱 NotificationManager: Updating settings")
    }
    
    func configureFromSettings(_ settings: NotificationSettings) async {
        // TODO: Реальная реализация
        print("📱 NotificationManager: Configuring from settings")
    }
    
    func sendImmediateNotification(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "immediate_\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📱 NotificationManager: Immediate notification sent")
        } catch {
            await MainActor.run {
                self.errorMessage = "Ошибка отправки уведомления: \(error.localizedDescription)"
            }
        }
    }
    
    func cancelAllNotifications() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        await updateScheduledNotifications()
        print("📱 NotificationManager: All notifications cancelled")
    }
    
    func updateScheduledNotifications() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        await MainActor.run {
            self.scheduledNotifications = requests
        }
    }
}

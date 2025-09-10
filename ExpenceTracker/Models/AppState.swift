//
//  AppState.swift
//  ExpenseTracker
//
//  Created by Developer on 24/06/2025.
//

import SwiftUI
import Combine

// MARK: - Единое состояние приложения (ИСПРАВЛЕНО)
@MainActor
final class AppState: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AppState()
    
    // MARK: - Dependencies (конкретные типы вместо протоколов для binding)
    private let coreDataManager: CoreDataManager
    private let settingsManager: UserSettingsManager
    private let notificationManager: NotificationManager
    
    // MARK: - Published State
    
    // Данные
    @Published var expenses: [Expense] = []
    @Published var categories: [Category] = []
    
    // Настройки (реактивные из settingsManager)
    @Published var userSettings: AppSettings
    
    // UI состояние
    @Published var selectedDate = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Аналитика (computed properties для производительности)
    @Published private var _selectedDateSpent: Double = 0
    @Published private var _todaySpent: Double = 0
    @Published private var _thisMonthSpent: Double = 0
    @Published private var _categorySpending: [UUID: Double] = [:]
    
    // MARK: - Computed Properties
    
    var selectedDateSpent: Double { _selectedDateSpent }
    var todaySpent: Double { _todaySpent }
    var thisMonthSpent: Double { _thisMonthSpent }
    var categorySpending: [UUID: Double] { _categorySpending }
    
    var selectedDateExpenses: [Expense] {
        let calendar = Calendar.current
        return expenses.filter { expense in
            calendar.isDate(expense.safeDate, inSameDayAs: selectedDate)
        }
    }
    
    var recentExpenses: [Expense] {
        Array(expenses.prefix(20))
    }
    
    var recentExpensesForHome: [Expense] {
        Array(selectedDateExpenses.prefix(4))
    }
    
    // Календарные helpers
    var weekDates: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    // MARK: - Private init (Singleton)
    private init() {
        // Создаём конкретные экземпляры менеджеров (НЕ протоколы!)
        self.coreDataManager = CoreDataManager()
        self.settingsManager = UserSettingsManager()
        self.notificationManager = NotificationManager()
        
        // Загружаем начальные настройки
        self.userSettings = settingsManager.settings
        
        setupBindings()
        
        print("✅ AppState: Initialized")
    }
    
    // Для тестов и превью (dependency injection с конкретными типами)
    init(
        coreDataManager: CoreDataManager,
        settingsManager: UserSettingsManager,
        notificationManager: NotificationManager
    ) {
        self.coreDataManager = coreDataManager
        self.settingsManager = settingsManager
        self.notificationManager = notificationManager
        self.userSettings = settingsManager.settings
        
        setupBindings()
        
        print("✅ AppState: Initialized with DI")
    }
    
    // MARK: - Reactive Bindings (ИСПРАВЛЕНО)
    private func setupBindings() {
        // ✅ ИСПРАВЛЕНО: Используем конкретный тип UserSettingsManager
        settingsManager.$settings
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .assign(to: &$userSettings)
        
        // ✅ ИСПРАВЛЕНО: Используем конкретные типы для errorPublisher
        Publishers.Merge3(
            coreDataManager.$_errorMessage.compactMap { $0 },
            settingsManager.$_errorMessage.compactMap { $0 },
            notificationManager.$errorMessage.compactMap { $0 }
        )
        .receive(on: DispatchQueue.main)
        .assign(to: &$errorMessage)
        
        // Реактивно пересчитываем аналитику при изменении данных
        Publishers.CombineLatest($expenses, $selectedDate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in
                self?.recalculateAnalytics()
            }
            .store(in: &cancellables)
        
        print("✅ AppState: Reactive bindings setup")
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Actions
    
    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }
        
        async let categoriesLoad = loadCategories()
        async let expensesLoad = loadExpenses()
        
        await categoriesLoad
        await expensesLoad
        
        recalculateAnalytics()
        
        print("✅ AppState: Initial data loaded")
    }
    
    func refreshData() async {
        async let categoriesRefresh = loadCategories()
        async let expensesRefresh = loadExpenses()
        
        await categoriesRefresh
        await expensesRefresh
        
        recalculateAnalytics()
        
        print("✅ AppState: Data refreshed")
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
        print("📅 AppState: Selected date changed to \(date)")
    }
    
    // MARK: - Expense Actions (делегируем в менеджеры)
    
    func addExpense(
        amount: Double,
        name: String,
        notes: String? = nil,
        categoryId: UUID,
        date: Date = Date()
    ) async -> Bool {
        
        guard let category = categories.first(where: { $0.identifier == categoryId }) else {
            handleError("Категория не найдена")
            return false
        }
        
        let success = await coreDataManager.addExpense(
            amount: amount,
            name: name,
            notes: notes,
            category: category,
            date: date
        )
        
        if success {
            await loadExpenses()
            recalculateAnalytics()
        }
        
        return success
    }
    
    func deleteExpense(_ expense: Expense) async -> Bool {
        // Оптимистичное обновление UI
        let originalExpenses = expenses
        expenses.removeAll { $0.identifier == expense.identifier }
        recalculateAnalytics()
        
        let success = await coreDataManager.deleteExpense(expense)
        
        if !success {
            // Откатываем изменения при ошибке
            expenses = originalExpenses
            recalculateAnalytics()
            handleError("Не удалось удалить трату")
        }
        
        return success
    }
    
    // MARK: - Category Actions (делегируем в менеджеры)
    
    func addCategory(name: String, icon: String, color: Color) async -> Bool {
        let success = await coreDataManager.addCategory(name: name, icon: icon, color: color)
        
        if success {
            await loadCategories()
        }
        
        return success
    }
    
    func updateCategory(_ category: Category, name: String? = nil, icon: String? = nil, color: Color? = nil) async -> Bool {
        let success = await coreDataManager.updateCategory(category, name: name, icon: icon, color: color)
        
        if success {
            await loadCategories()
        }
        
        return success
    }
    
    func deleteCategory(_ category: Category) async -> Bool {
        let success = await coreDataManager.deleteCategory(category)
        
        if success {
            await loadCategories()
        }
        
        return success
    }
    
    // MARK: - Settings Actions (делегируем в UserSettingsManager)
    
    func updateCurrency(_ currency: Currency) {
        settingsManager.updateCurrency(currency)
        // Настройки автоматически обновятся через binding
    }
    
    func updateTheme(_ theme: AppTheme) {
        settingsManager.updateTheme(theme)
    }
    
    func updateUserProfile(name: String, email: String?) {
        settingsManager.updateUserName(name)
        settingsManager.updateUserEmail(email)
    }
    
    func updateBudgetSettings(daily: Double?, monthly: Double?, enabled: Bool) {
        settingsManager.updateDailyBudget(daily)
        settingsManager.updateMonthlyBudget(monthly)
        settingsManager.toggleBudgetEnabled(enabled)
    }
    
    // MARK: - Notification Actions
    
    func updateNotificationSettings(_ settings: NotificationSettings) async {
        await notificationManager.updateSettings(settings)
        settingsManager.updateNotificationSettings(settings)
    }
    
    // MARK: - Utility Actions
    
    func clearError() {
        errorMessage = nil
    }
    
    func formatAmount(_ amount: Double) -> String {
        return userSettings.currency.formatAmount(amount, format: userSettings.numberFormat)
    }
    
    // MARK: - Private Methods
    
    private func loadCategories() async {
        do {
            categories = try await coreDataManager.loadCategories()
            print("📂 AppState: Loaded \(categories.count) categories")
        } catch {
            handleError("Ошибка загрузки категорий: \(error.localizedDescription)")
        }
    }
    
    private func loadExpenses() async {
        do {
            expenses = try await coreDataManager.loadRecentExpenses(limit: 100)
            print("📊 AppState: Loaded \(expenses.count) expenses")
        } catch {
            handleError("Ошибка загрузки трат: \(error.localizedDescription)")
        }
    }
    
    private func recalculateAnalytics() {
        let calendar = Calendar.current
        let today = Date()
        
        // Траты за выбранную дату
        _selectedDateSpent = selectedDateExpenses.reduce(0) { $0 + $1.amount }
        
        // Траты за сегодня
        let todayExpenses = expenses.filter { calendar.isDateInToday($0.safeDate) }
        _todaySpent = todayExpenses.reduce(0) { $0 + $1.amount }
        
        // Траты за текущий месяц
        let monthExpenses = expenses.filter { expense in
            guard let monthInterval = calendar.dateInterval(of: .month, for: today) else { return false }
            return expense.safeDate >= monthInterval.start && expense.safeDate < monthInterval.end
        }
        _thisMonthSpent = monthExpenses.reduce(0) { $0 + $1.amount }
        
        // Траты по категориям за выбранную дату
        var spending: [UUID: Double] = [:]
        for expense in selectedDateExpenses {
            if let categoryId = expense.category?.id {
                spending[categoryId, default: 0] += expense.amount
            }
        }
        _categorySpending = spending
        
        print("💰 AppState: Analytics recalculated - Selected: $\(_selectedDateSpent), Today: $\(_todaySpent), Month: $\(_thisMonthSpent)")
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        print("❌ AppState Error: \(message)")
    }
}

// MARK: - Calendar Helpers
extension AppState {
    func dayAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ru_RU")
        return String(formatter.string(from: date).prefix(1)).uppercased()
    }
    
    func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    func isSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: selectedDate)
    }
    
    var formattedDayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: selectedDate).capitalized
    }
}

// MARK: - Preview Support (ИСПРАВЛЕНО)
extension AppState {
    static let preview: AppState = {
        // Создаём конкретные mock'и
        let mockCoreData = CoreDataManager()
        let mockSettings = UserSettingsManager()
        let mockNotifications = NotificationManager()
        
        return AppState(
            coreDataManager: mockCoreData,
            settingsManager: mockSettings,
            notificationManager: mockNotifications
        )
    }()
}

//
//  ExpenseViewModel.swift - ОБНОВЛЕН: простое переключение экранов
//  ExpenseTracker
//
//  Created by Developer on 24/06/2025.
//

import SwiftUI
import Foundation
import Combine

// MARK: - Лёгкий ExpenseViewModel как адаптер к AppState
@MainActor
final class ExpenseViewModel: ObservableObject {
    
    // MARK: - Reference to AppState (не владеем им!)
    private let appState: AppState
    
    // MARK: - UI State (только для UI логики)
    @Published var showingAddExpense = false
    @Published var showingProfile = false // ✅ Теперь это простое переключение экранов
    @Published var showingTodayExpenses = false // ✅ НОВОЕ: сегодняшние траты
    @Published var showingAllExpenses = false // ✅ Полная статистика
    @Published var showFullStats = false
    
    // MARK: - Новые состояния для чистого дизайна
    @Published var showingSearch = false
    @Published var showingQuickActions = false
    
    // MARK: - Cancellables для подписок
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(appState: AppState) {
        self.appState = appState
        // ✅ УБРАЛИ setupNotificationObservers() - больше не нужны
        print("✅ ExpenseViewModel: Initialized as AppState adapter")
    }
    
    // MARK: - Computed Properties (прямой доступ к AppState)
    
    // Данные
    var expenses: [Expense] { appState.expenses }
    var categories: [Category] { appState.categories }
    var selectedDate: Date { appState.selectedDate }
    
    // Аналитика
    var todaySpent: Double { appState.todaySpent }
    var thisMonthSpent: Double { appState.thisMonthSpent }
    var selectedDateSpent: Double { appState.selectedDateSpent }
    var displayedSpent: Double { appState.selectedDateSpent }
    var categorySpendingForSelectedDate: [UUID: Double] { appState.categorySpending }
    
    // Списки для UI
    var recentExpenses: [Expense] { appState.recentExpenses }
    var recentExpensesForHome: [Expense] { appState.recentExpensesForHome }
    var selectedDateExpenses: [Expense] { appState.selectedDateExpenses }
    
    // Календарные свойства
    var formattedDate: String { appState.formattedDate }
    var formattedDayOfWeek: String { appState.formattedDayOfWeek }
    var weekDates: [Date] { appState.weekDates }
    
    // Системное состояние
    var isLoading: Bool { appState.isLoading }
    var errorMessage: String? { appState.errorMessage }
    var showingErrorAlert: Bool { appState.errorMessage != nil }
    
    // MARK: - Actions (делегируем в AppState)
    
    func loadInitialData() async {
        await appState.loadInitialData()
    }
    
    func refreshData() async {
        await appState.refreshData()
    }
    
    func selectDate(_ date: Date) {
        appState.selectDate(date)
    }
    
    func addExpense(
        amount: Double,
        name: String,
        notes: String? = nil,
        categoryId: UUID,
        date: Date = Date()
    ) async -> Bool {
        
        let success = await appState.addExpense(
            amount: amount,
            name: name,
            notes: notes,
            categoryId: categoryId,
            date: date
        )
        
        // Закрываем модальное окно при успехе
        if success {
            showingAddExpense = false
        }
        
        return success
    }
    
    func deleteExpense(_ expense: Expense) async -> Bool {
        return await appState.deleteExpense(expense)
    }
    
    func addCategory(name: String, icon: String, color: Color) async -> Bool {
        return await appState.addCategory(name: name, icon: icon, color: color)
    }
    
    func updateCategory(_ category: Category, name: String? = nil, icon: String? = nil, color: Color? = nil) async -> Bool {
        return await appState.updateCategory(category, name: name, icon: icon, color: color)
    }
    
    func deleteCategory(_ category: Category) async -> Bool {
        return await appState.deleteCategory(category)
    }
    
    // MARK: - Calendar Helpers (делегируем в AppState)
    
    func dayAbbreviation(for date: Date) -> String {
        appState.dayAbbreviation(for: date)
    }
    
    func dayNumber(for date: Date) -> String {
        appState.dayNumber(for: date)
    }
    
    func isToday(_ date: Date) -> Bool {
        appState.isToday(date)
    }
    
    func isSelected(_ date: Date) -> Bool {
        appState.isSelected(date)
    }
    
    // MARK: - Error Handling (делегируем в AppState)
    
    func clearError() {
        appState.clearError()
    }
    
    // MARK: - UI Actions (только UI логика остаётся здесь)
    
    func showAddExpense() {
        showingAddExpense = true
    }
    
    func hideAddExpense() {
        showingAddExpense = false
    }
    
    // ✅ УПРОЩЕННЫЕ методы для профиля - простое переключение
    func showProfile() {
        showingProfile = true
        print("📱 ExpenseViewModel: Showing profile screen")
    }
    
    func hideProfile() {
        showingProfile = false
        print("📱 ExpenseViewModel: Hiding profile screen")
    }
    
    func showTodayExpenses() {
        showingTodayExpenses = true
    }
    
    func hideTodayExpenses() {
        showingTodayExpenses = false
    }
    
    func showAllExpenses() {
        showingAllExpenses = true
    }
    
    func hideAllExpenses() {
        showingAllExpenses = false
    }
    
    func showStats() {
        showFullStats = true
    }
    
    func hideStats() {
        showFullStats = false
    }
    
    // MARK: - Новые UI Actions для чистого дизайна
    
    func showSearch() {
        showingSearch = true
    }
    
    func hideSearch() {
        showingSearch = false
    }
    
    func showQuickActions() {
        showingQuickActions = true
    }
    
    func hideQuickActions() {
        showingQuickActions = false
    }
    
    // MARK: - Helper Methods для UI
    
    func formatAmount(_ amount: Double) -> String {
        return appState.formatAmount(amount)
    }
    
    func getExpensesForCategory(_ category: Category) -> [Expense] {
        return expenses.filter { $0.category?.identifier == category.identifier }
    }
    
    func getTotalForCategory(_ category: Category) -> Double {
        return getExpensesForCategory(category).reduce(0) { $0 + $1.amount }
    }
    
    func getExpenseCountForCategory(_ category: Category) -> Int {
        return getExpensesForCategory(category).count
    }
    
    // MARK: - Reactive Updates (упрощено)
    
    func setupUIReactions() {
        // Автоматически скрываем модальные окна при ошибках
        appState.$errorMessage
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.hideAddExpense()
                self?.hideSearch()
                self?.hideQuickActions()
                // ✅ НЕ скрываем профиль при ошибках - это полноценный экран
            }
            .store(in: &cancellables)
        
        print("✅ ExpenseViewModel: UI reactions setup")
    }
    
    // MARK: - Cleanup
    
    deinit {
        cancellables.removeAll()
        print("🗑️ ExpenseViewModel: Deallocated")
    }
}

// MARK: - Convenience Computed Properties для специфичных UI случаев
extension ExpenseViewModel {
    
    // Есть ли траты за выбранную дату
    var hasExpensesForSelectedDate: Bool {
        !selectedDateExpenses.isEmpty
    }
    
    // Есть ли траты вообще
    var hasAnyExpenses: Bool {
        !expenses.isEmpty
    }
    
    // Количество категорий
    var categoriesCount: Int {
        categories.count
    }
    
    // Есть ли активные категории
    var hasCategories: Bool {
        !categories.isEmpty
    }
    
    // Топ категория по тратам за выбранную дату
    var topCategoryForSelectedDate: Category? {
        guard !categorySpendingForSelectedDate.isEmpty else { return nil }
        
        let topCategoryId = categorySpendingForSelectedDate.max { $0.value < $1.value }?.key
        return categories.first { $0.identifier == topCategoryId }
    }
    
    // Процент от месячного бюджета (если установлен)
    var monthlyBudgetUsagePercentage: Double? {
        guard let monthlyBudget = appState.userSettings.budgetSettings.monthlyBudget,
              monthlyBudget > 0 else { return nil }
        
        return min(thisMonthSpent / monthlyBudget, 1.0)
    }
    
    // Превышен ли бюджет
    var isBudgetExceeded: Bool {
        guard let percentage = monthlyBudgetUsagePercentage else { return false }
        return percentage > 1.0
    }
    
    // Приближается ли к лимиту бюджета (>75%)
    var isBudgetNearLimit: Bool {
        guard let percentage = monthlyBudgetUsagePercentage else { return false }
        return percentage > 0.75
    }
    
    // ✅ НОВОЕ: удобный computed property для состояния экрана
    var currentScreen: AppScreen {
        if showingProfile {
            return .profile
        } else {
            return .home
        }
    }
}

// ✅ НОВОЕ: Enum для определения текущего экрана
enum AppScreen {
    case home
    case profile
    
    var description: String {
        switch self {
        case .home: return "Главный экран"
        case .profile: return "Профиль"
        }
    }
}

// MARK: - Factory Methods для создания ViewModel'и
extension ExpenseViewModel {
    
    // Стандартный ViewModel с общим AppState
    static func standard() -> ExpenseViewModel {
        return ExpenseViewModel(appState: AppState.shared)
    }
    
    // ViewModel для Preview с mock данными
    static let preview: ExpenseViewModel = {
        return ExpenseViewModel(appState: AppState.preview)
    }()
    
    // ViewModel для тестов с заданным AppState
    static func forTesting(appState: AppState) -> ExpenseViewModel {
        return ExpenseViewModel(appState: appState)
    }
}

// MARK: - Backwards Compatibility (временно, пока не обновим все View)
extension ExpenseViewModel {
    
    // Эти методы оставляем для совместимости со старыми View,
    // потом уберём когда обновим все компоненты
    
    @available(*, deprecated, message: "Use appState.expenses directly")
    var allExpenses: [Expense] { expenses }
    
    @available(*, deprecated, message: "Use selectDate() instead")
    func updateSelectedDate(_ date: Date) {
        selectDate(date)
    }
}

// MARK: - Debug Helpers
#if DEBUG
extension ExpenseViewModel {
    
    func printCurrentState() {
        print("🐛 ExpenseViewModel Debug State:")
        print("   Current screen: \(currentScreen.description)")
        print("   Expenses count: \(expenses.count)")
        print("   Categories count: \(categories.count)")
        print("   Selected date: \(formattedDate)")
        print("   Today spent: $\(todaySpent)")
        print("   Month spent: $\(thisMonthSpent)")
        print("   UI States:")
        print("     - showingAddExpense: \(showingAddExpense)")
        print("     - showingProfile: \(showingProfile)")
        print("     - showingTodayExpenses: \(showingTodayExpenses)")
        print("     - showingAllExpenses: \(showingAllExpenses)")
        print("     - showFullStats: \(showFullStats)")
        print("     - showingSearch: \(showingSearch)")
        print("     - showingQuickActions: \(showingQuickActions)")
    }
    
    func simulateAddExpense() {
        Task {
            guard let firstCategory = categories.first else {
                print("🐛 No categories available for simulation")
                return
            }
            
            let success = await addExpense(
                amount: Double.random(in: 10...100),
                name: "Test Expense",
                categoryId: firstCategory.identifier
            )
            
            print("🐛 Simulated expense addition: \(success ? "SUCCESS" : "FAILED")")
        }
    }
    
    // ✅ НОВОЕ: симуляция переключения экранов
    func simulateScreenNavigation() {
        print("🐛 Simulating screen navigation...")
        
        if showingProfile {
            hideProfile()
        } else {
            showProfile()
        }
    }
}
#endif

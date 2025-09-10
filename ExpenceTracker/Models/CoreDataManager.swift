//
//  CoreDataManager.swift
//  ExpenseTracker
//
//  Created by Developer on 24/06/2025.
//

import CoreData
import SwiftUI
import Foundation
import Combine

// MARK: - Рефакторенный Core Data Manager
@MainActor
final class CoreDataManager: CoreDataManagerProtocol {
    
    // MARK: - Published Properties для протокола
    @Published internal var _errorMessage: String?
    
    var errorPublisher: AnyPublisher<String?, Never> {
        $_errorMessage.eraseToAnyPublisher()
    }
    
    // MARK: - Core Data Stack
    private let coreDataStack = CoreDataStack.shared
    
    private var viewContext: NSManagedObjectContext {
        coreDataStack.viewContext
    }
    
    // MARK: - Cache для производительности
    private var categoriesCache: [Category] = []
    private var cacheTimestamp: Date?
    private let cacheValidityDuration: TimeInterval = 300 // 5 минут
    
    // MARK: - Initialization
    init() {
        setupNotifications()
        print("✅ CoreDataManager: Initialized")
    }
    
    // MARK: - Notifications Setup
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSave),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
    }
    
    @objc private func contextDidSave() {
        invalidateCache()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Categories Implementation
    
    func loadCategories() async throws -> [Category] {
        // Проверяем кеш
        if let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheValidityDuration,
           !categoriesCache.isEmpty {
            print("📂 CoreDataManager: Returning cached categories")
            return categoriesCache
        }
        
        do {
            let request: NSFetchRequest<Category> = Category.fetchRequest()
            request.predicate = NSPredicate(format: "isActive == true")
            request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            
            let fetchedCategories = try viewContext.fetch(request)
            
            // Создаём дефолтные категории если их нет
            if fetchedCategories.isEmpty {
                print("📦 CoreDataManager: Creating default categories")
                let defaultCategories = Category.createDefaultCategories(in: viewContext)
                
                if await saveContextSafely() {
                    categoriesCache = defaultCategories
                    cacheTimestamp = Date()
                    return defaultCategories
                } else {
                    throw CoreDataError.saveFailed("Не удалось создать дефолтные категории")
                }
            }
            
            categoriesCache = fetchedCategories
            cacheTimestamp = Date()
            
            print("📂 CoreDataManager: Loaded \(fetchedCategories.count) categories")
            return fetchedCategories
            
        } catch {
            let errorMessage = "Ошибка загрузки категорий: \(error.localizedDescription)"
            await handleError(errorMessage)
            throw CoreDataError.loadFailed(errorMessage)
        }
    }
    
    func addCategory(name: String, icon: String, color: Color) async -> Bool {
        // Валидация
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await handleError("Название категории не может быть пустым")
            return false
        }
        
        // Проверяем уникальность
        do {
            let existingCategories = try await loadCategories()
            if existingCategories.contains(where: { $0.safeName.lowercased() == name.lowercased() }) {
                await handleError("Категория с таким названием уже существует")
                return false
            }
            
            let newOrder = Int32((existingCategories.map { Int($0.order) }.max() ?? -1) + 1)
            
            let category = Category(
                context: viewContext,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                icon: icon,
                colorHex: color.hexString,
                order: newOrder
            )
            
            do {
                if try await saveContext() {
                    invalidateCache()
                    print("✅ CoreDataManager: Category '\(name)' added successfully")
                    return true
                } else {
                    return false
                }
            } catch {
                await handleError("Ошибка добавления категории: \(error.localizedDescription)")
                return false
            }
            
        } catch {
            await handleError("Ошибка добавления категории: \(error.localizedDescription)")
            return false
        }
    }
    
    func updateCategory(_ category: Category, name: String? = nil, icon: String? = nil, color: Color? = nil) async -> Bool {
        // Обновляем только переданные параметры
        if let name = name {
            category.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let icon = icon {
            category.icon = icon
        }
        
        if let color = color {
            category.colorHex = color.hexString
        }
        
        if await saveContextSafely() {
            invalidateCache()
            print("✅ CoreDataManager: Category updated successfully")
            return true
        } else {
            await handleError("Не удалось обновить категорию")
            return false
        }
    }
    
    func deleteCategory(_ category: Category) async -> Bool {
        // Soft delete - помечаем как неактивную
        category.isActive = false
        
        if await saveContextSafely() {
            invalidateCache()
            print("✅ CoreDataManager: Category soft deleted")
            return true
        } else {
            await handleError("Не удалось удалить категорию")
            return false
        }
    }
    
    func reorderCategories(_ categories: [Category]) async -> Bool {
        // Обновляем порядок категорий
        for (index, category) in categories.enumerated() {
            category.order = Int32(index)
        }
        
        if await saveContextSafely() {
            invalidateCache()
            print("✅ CoreDataManager: Categories reordered")
            return true
        } else {
            await handleError("Не удалось изменить порядок категорий")
            return false
        }
    }
    
    // MARK: - Expenses Implementation
    
    func loadRecentExpenses(limit: Int = 100) async throws -> [Expense] {
        do {
            let request: NSFetchRequest<Expense> = Expense.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            request.fetchLimit = limit
            
            let expenses = try viewContext.fetch(request)
            print("📊 CoreDataManager: Loaded \(expenses.count) expenses")
            return expenses
            
        } catch {
            let errorMessage = "Ошибка загрузки трат: \(error.localizedDescription)"
            await handleError(errorMessage)
            throw CoreDataError.loadFailed(errorMessage)
        }
    }
    
    func addExpense(
        amount: Double,
        name: String,
        notes: String? = nil,
        category: Category,
        date: Date = Date()
    ) async -> Bool {
        
        // Валидация
        guard await validateExpenseInput(amount: amount, name: name, date: date) else {
            return false
        }
        
        let expense = Expense(
            context: viewContext,
            amount: amount,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes?.isEmpty == true ? nil : notes,
            date: date,
            category: category
        )
        
        if await saveContextSafely() {
            print("✅ CoreDataManager: Expense '\(name)' added successfully")
            return true
        } else {
            return false
        }
    }
    
    func deleteExpense(_ expense: Expense) async -> Bool {
        viewContext.delete(expense)
        
        if await saveContextSafely() {
            print("✅ CoreDataManager: Expense deleted successfully")
            return true
        } else {
            await handleError("Не удалось удалить трату")
            return false
        }
    }
    
    func getExpensesForDate(_ date: Date) async -> [Expense] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return await getExpensesForDateRange(from: startOfDay, to: endOfDay)
    }
    
    func getTotalForDate(_ date: Date) async -> Double {
        do {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let request: NSFetchRequest<Expense> = Expense.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
            
            let expenses = try viewContext.fetch(request)
            return expenses.reduce(0) { $0 + $1.amount }
            
        } catch {
            await handleError("Ошибка расчёта суммы за дату: \(error.localizedDescription)")
            return 0
        }
    }
    
    func getTotalForCurrentMonth() async -> Double {
        do {
            let calendar = Calendar.current
            let now = Date()
            guard let monthInterval = calendar.dateInterval(of: .month, for: now) else {
                return 0
            }
            
            let request: NSFetchRequest<Expense> = Expense.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                          monthInterval.start as NSDate,
                                          monthInterval.end as NSDate)
            
            let expenses = try viewContext.fetch(request)
            return expenses.reduce(0) { $0 + $1.amount }
            
        } catch {
            await handleError("Ошибка расчёта месячной суммы: \(error.localizedDescription)")
            return 0
        }
    }
    
    func getCategorySpendingForDate(_ date: Date) async -> [UUID: Double] {
        let expenses = await getExpensesForDate(date)
        var spending: [UUID: Double] = [:]
        
        for expense in expenses {
            if let categoryId = expense.category?.id {
                spending[categoryId, default: 0] += expense.amount
            }
        }
        
        return spending
    }
    
    // MARK: - Analytics Implementation
    
    func getCategoryExpenseCount(_ category: Category) async -> Int {
        do {
            let request: NSFetchRequest<Expense> = Expense.fetchRequest()
            request.predicate = NSPredicate(format: "category == %@", category)
            
            return try viewContext.count(for: request)
            
        } catch {
            await handleError("Ошибка подсчёта трат категории: \(error.localizedDescription)")
            return 0
        }
    }
    
    func getCategoryTotalAmount(_ category: Category) async -> Double {
        do {
            let request: NSFetchRequest<Expense> = Expense.fetchRequest()
            request.predicate = NSPredicate(format: "category == %@", category)
            
            let expenses = try viewContext.fetch(request)
            return expenses.reduce(0) { $0 + $1.amount }
            
        } catch {
            await handleError("Ошибка расчёта суммы категории: \(error.localizedDescription)")
            return 0
        }
    }
    
    func searchExpenses(query: String) async -> [Expense] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        do {
            let request: NSFetchRequest<Expense> = Expense.fetchRequest()
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", query, query)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            return try viewContext.fetch(request)
            
        } catch {
            await handleError("Ошибка поиска трат: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func getExpensesForDateRange(from startDate: Date, to endDate: Date) async -> [Expense] {
        do {
            let request: NSFetchRequest<Expense> = Expense.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startDate as NSDate, endDate as NSDate)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            return try viewContext.fetch(request)
            
        } catch {
            await handleError("Ошибка загрузки трат за период: \(error.localizedDescription)")
            return []
        }
    }
    
    private func validateExpenseInput(amount: Double, name: String, date: Date) async -> Bool {
        // Проверка суммы
        if amount <= 0 {
            await handleError("Сумма должна быть больше нуля")
            return false
        }
        
        if amount > 1_000_000 {
            await handleError("Сумма слишком большая")
            return false
        }
        
        // Проверка названия
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            await handleError("Название траты не может быть пустым")
            return false
        }
        
        // Проверка даты
        let calendar = Calendar.current
        let now = Date()
        let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        
        if date > tomorrow {
            await handleError("Дата не может быть в будущем")
            return false
        }
        
        if date < startOfYear {
            await handleError("Дата не может быть раньше начала текущего года")
            return false
        }
        
        return true
    }
    
    // MARK: - Context Management
    
    // Безопасное сохранение без throws
    private func saveContextSafely() async -> Bool {
        guard viewContext.hasChanges else {
            return true
        }
        
        do {
            try viewContext.save()
            print("✅ CoreDataManager: Context saved successfully")
            return true
        } catch {
            let errorMessage = "Ошибка сохранения: \(error.localizedDescription)"
            await handleError(errorMessage)
            return false
        }
    }
    
    // Сохранение с throws для специальных случаев
    @discardableResult
    private func saveContext() async throws -> Bool {
        guard viewContext.hasChanges else {
            return true
        }
        
        do {
            try viewContext.save()
            print("✅ CoreDataManager: Context saved successfully")
            return true
        } catch {
            let errorMessage = "Ошибка сохранения: \(error.localizedDescription)"
            await handleError(errorMessage)
            throw CoreDataError.saveFailed(errorMessage)
        }
    }
    
    // MARK: - Cache Management
    
    private func invalidateCache() {
        categoriesCache.removeAll()
        cacheTimestamp = nil
        print("🗑️ CoreDataManager: Cache invalidated")
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ message: String) async {
        await MainActor.run {
            _errorMessage = message
            print("❌ CoreDataManager Error: \(message)")
        }
    }
    
    func clearError() {
        _errorMessage = nil
    }
}

// MARK: - Core Data Error Types
enum CoreDataError: LocalizedError {
    case saveFailed(String)
    case loadFailed(String)
    case deleteFailed(String)
    case validationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "Ошибка сохранения: \(message)"
        case .loadFailed(let message):
            return "Ошибка загрузки: \(message)"
        case .deleteFailed(let message):
            return "Ошибка удаления: \(message)"
        case .validationFailed(let message):
            return "Ошибка валидации: \(message)"
        }
    }
}

// MARK: - Development Helpers
#if DEBUG
extension CoreDataManager {
    func printDatabaseStats() async {
        do {
            let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
            let expenseRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
            
            let categoryCount = try viewContext.count(for: categoryRequest)
            let expenseCount = try viewContext.count(for: expenseRequest)
            
            print("📊 Database Stats:")
            print("   Categories: \(categoryCount)")
            print("   Expenses: \(expenseCount)")
            
        } catch {
            print("❌ Failed to get database stats: \(error)")
        }
    }
    
    func deleteAllData() async {
        coreDataStack.deleteAllData()
        invalidateCache()
        print("🗑️ CoreDataManager: All data deleted")
    }
}
#endif

// MARK: - Preview Support
extension CoreDataManager {
    static let preview: CoreDataManager = {
        CoreDataManager()
    }()
}

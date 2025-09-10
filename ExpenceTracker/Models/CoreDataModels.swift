//
//  CoreDataModels.swift
//  ExpenseTracker
//
//  Created by Developer on 21/06/2025.
//

import CoreData
import SwiftUI
import Foundation

// MARK: - Category Entity
@objc(Category)
public class Category: NSManagedObject {
    
    // Computed property для получения Color из hex
    var color: Color {
        Color(hex: colorHex ?? "000000")
    }
    
    // Computed property для безопасного доступа к имени
    var safeName: String {
        name ?? "Без названия"
    }
    
    // Computed property для безопасного доступа к иконке
    var safeIcon: String {
        icon ?? "questionmark"
    }
    
    // Convenience initializer
    convenience init(context: NSManagedObjectContext, name: String, icon: String, colorHex: String, order: Int32 = 0) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.order = order
        self.isActive = true
        self.createdAt = Date()
    }
}

// MARK: - Category Core Data Properties
extension Category {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var icon: String?
    @NSManaged public var colorHex: String?
    @NSManaged public var order: Int32
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var expenses: NSSet?
}

// MARK: - Category Relationships
extension Category {
    
    @objc(addExpensesObject:)
    @NSManaged public func addToExpenses(_ value: Expense)
    
    @objc(removeExpensesObject:)
    @NSManaged public func removeFromExpenses(_ value: Expense)
    
    @objc(addExpenses:)
    @NSManaged public func addToExpenses(_ values: NSSet)
    
    @objc(removeExpenses:)
    @NSManaged public func removeFromExpenses(_ values: NSSet)
    
    // Convenience computed property
    var expensesArray: [Expense] {
        let set = expenses as? Set<Expense> ?? []
        return set.sorted { $0.safeDate > $1.safeDate }
    }
}

// MARK: - Expense Entity
@objc(Expense)
public class Expense: NSManagedObject {
    
    // Computed properties для UI
    var formattedAmount: String {
        String(format: "%.2f", amount)
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: safeDate)
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: safeDate)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(safeDate)
    }
    
    // Безопасные свойства
    var safeName: String {
        name ?? "Без названия"
    }
    
    var safeDate: Date {
        date ?? Date()
    }
    
    // Convenience initializer
    convenience init(context: NSManagedObjectContext, amount: Double, name: String, notes: String? = nil, date: Date = Date(), category: Category? = nil) {
        self.init(context: context)
        self.id = UUID()
        self.amount = amount
        self.name = name
        self.notes = notes
        self.date = date
        self.category = category
        self.createdAt = Date()
    }
}

// MARK: - Expense Core Data Properties
extension Expense {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Expense> {
        return NSFetchRequest<Expense>(entityName: "Expense")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var amount: Double
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var date: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var category: Category?
}

// MARK: - Identifiable Conformance
extension Category: Identifiable {
    public var identifier: UUID {
        id ?? UUID()
    }
}

extension Expense: Identifiable {
    public var identifier: UUID {
        id ?? UUID()
    }
}

// MARK: - Default Categories Data
extension Category {
    static let defaultCategories: [(name: String, icon: String, colorHex: String)] = [
        ("Еда", "fork.knife", "FF6B35"), // Orange
        ("Транспорт", "car.fill", "007AFF"), // Blue
        ("Жилье", "house.fill", "34C759"), // Green
        ("Покупки", "bag.fill", "FF2D92"), // Pink
        ("Досуг", "tv.fill", "AF52DE"), // Purple
        ("Здоровье", "heart.fill", "FF3B30"), // Red
        ("Образование", "book.fill", "5856D6"), // Purple Blue
        ("Путешествия", "airplane", "00C7BE") // Teal
    ]
    
    static func createDefaultCategories(in context: NSManagedObjectContext) -> [Category] {
        return defaultCategories.enumerated().map { index, categoryData in
            Category(
                context: context,
                name: categoryData.name,
                icon: categoryData.icon,
                colorHex: categoryData.colorHex,
                order: Int32(index)
            )
        }
    }
}

// MARK: - Color Extension (Same as before)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    var hexString: String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

// MARK: - Analytics Models (Same as before)
struct CategorySpending {
    let category: Category
    let amount: Double
    let percentage: Double
    let expenseCount: Int
}

struct DailySpending {
    let date: Date
    let amount: Double
    let expenseCount: Int
}

// MARK: - App Error Types (Same as before)
enum ExpenseError: LocalizedError {
    case invalidInput(String)
    case saveFailed(String)
    case deleteFailed(String)
    case loadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Неверные данные: \(message)"
        case .saveFailed(let message):
            return "Ошибка сохранения: \(message)"
        case .deleteFailed(let message):
            return "Ошибка удаления: \(message)"
        case .loadFailed(let message):
            return "Ошибка загрузки: \(message)"
        }
    }
}

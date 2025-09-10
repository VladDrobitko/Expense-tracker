//
//  CategoryComponents.swift
//  ExpenseTracker
//
//  Created by Developer on 21/06/2025.
//

import SwiftUI

// MARK: - Categories View
struct CategoriesView: View {
    let categories: [Category]
    let selectedDate: Date
    let categorySpending: [UUID: Double]
    let onCategoryTap: (Category) -> Void
    let onAddCategoryTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Категории")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Настроить") {
                    // TODO: Открыть экран настройки категорий
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.expensePurple)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(categories, id: \.identifier) { category in
                        CategoryCard(
                            category: category,
                            selectedDate: selectedDate,
                            selectedDateSpent: categorySpending[category.identifier] ?? 0
                        ) {
                            onCategoryTap(category)
                        }
                    }
                    
                    AddCategoryCard {
                        onAddCategoryTap()
                    }
                }
                
                .padding(.trailing, 20) // Справа 20
            }
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: Category
    let selectedDate: Date
    let selectedDateSpent: Double
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Иконка с цветным кольцом
                ZStack {
                    Circle()
                        .fill(.regularMaterial)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(category.color.opacity(0.3), lineWidth: 2)
                        )
                    
                    Image(systemName: category.safeIcon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(category.color)
                }
                
                // Информация о категории
                VStack(spacing: 3) {
                    Text(category.safeName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(String(format: "$%.0f", selectedDateSpent))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(category.color)
                    
                    if selectedDateSpent > 0 {
                        Text(dateLabel)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(category.color.opacity(0.1))
                            )
                    } else {
                        Text("не тратили")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 110)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedDateSpent > 0 ? category.color.opacity(0.2) : .clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var dateLabel: String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(selectedDate) {
            return "сегодня"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "вчера"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            formatter.locale = Locale(identifier: "ru_RU")
            return formatter.string(from: selectedDate)
        }
    }
}

// MARK: - Add Category Card
struct AddCategoryCard: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Иконка добавления
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(Color.expensePurple.opacity(0.3), lineWidth: 2)
                                .overlay(
                                    Circle()
                                        .stroke(Color.expensePurple.opacity(0.1), lineWidth: 1)
                                        .scaleEffect(1.2)
                                )
                        )
                    
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.expensePurple)
                }
                
                VStack(spacing: 3) {
                    Text("Добавить")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("категорию")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 110)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.expensePurple.opacity(0.2), lineWidth: 1.5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.expensePurple.opacity(0.1), lineWidth: 1)
                                    .scaleEffect(1.02)
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Selection Button (для модального окна)
struct CategorySelectionButton: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.color : Color(.systemGray6))
                        .frame(width: 44, height: 44)
                    
                    if !isSelected {
                        Circle()
                            .stroke(category.color, lineWidth: 2)
                            .frame(width: 44, height: 44)
                    }
                    
                    Image(systemName: category.safeIcon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .white : category.color)
                }
                
                Text(category.safeName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? category.color : .secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .padding(2)
    }
}

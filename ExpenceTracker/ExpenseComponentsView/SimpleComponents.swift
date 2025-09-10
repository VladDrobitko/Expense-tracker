//
//  SimpleComponents.swift - Упрощенные компоненты для чистого дизайна
//  ExpenseTracker
//
//  Created by Developer on 24/06/2025.
//

import SwiftUI

// MARK: - Simple Expense Card (для списков)
struct SimpleExpenseCard: View {
    let expense: Expense
    let onTap: () -> Void
    let onDelete: (() -> Void)?
    let onEdit: (() -> Void)?
    
    @State private var showingActionSheet = false
    @State private var showingDeleteAlert = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Компактная иконка категории
                CategoryIconCompact(category: expense.category)
                
                // Информация о трате
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.safeName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    HStack(spacing: 8) {
                        if let category = expense.category {
                            Text(category.safeName)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(category.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(category.color.opacity(0.12))
                                )
                                .lineLimit(1)
                        }
                        
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            
                            Text(expense.timeString)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer(minLength: 8)
                
                // Сумма и дата
                VStack(alignment: .trailing, spacing: 3) {
                    Text("$\(expense.formattedAmount)")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(expense.isToday ? "сегодня" : relativeDateString(for: expense.safeDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(minWidth: 65)
                
                // Компактная кнопка меню
                if onDelete != nil || onEdit != nil {
                    Button(action: { showingActionSheet = true }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(.quaternary)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minHeight: 68)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .shadow(
                        color: .black.opacity(colorScheme == .dark ? 0.15 : 0.04),
                        radius: 6,
                        x: 0,
                        y: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .confirmationDialog("Действия", isPresented: $showingActionSheet) {
            if let onEdit = onEdit {
                Button("Изменить") {
                    onEdit()
                }
            }
            
            if let onDelete = onDelete {
                Button("Удалить", role: .destructive) {
                    showingDeleteAlert = true
                }
            }
            
            Button("Отмена", role: .cancel) { }
        }
        .alert("Удалить трату?", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("Трата \"\(expense.safeName)\" на сумму $\(expense.formattedAmount) будет удалена безвозвратно.")
        }
    }
    
    private func relativeDateString(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInYesterday(date) {
            return "вчера"
        } else if let days = calendar.dateComponents([.day], from: date, to: now).day, days > 0, days <= 7 {
            return "\(days)д"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            formatter.locale = Locale(identifier: "ru_RU")
            return formatter.string(from: date)
        }
    }
}

// MARK: - Компактная иконка категории
struct CategoryIconCompact: View {
    let category: Category?
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.regularMaterial)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(category?.color.opacity(0.25) ?? Color.secondary.opacity(0.25), lineWidth: 1.5)
                )
            
            if let category = category {
                Image(systemName: category.safeIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(category.color)
            } else {
                Image(systemName: "questionmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .shadow(
            color: (category?.color ?? .secondary).opacity(0.15),
            radius: 3,
            x: 0,
            y: 1
        )
    }
}

// MARK: - Увеличенная иконка категории
struct CategoryIconLarge: View {
    let category: Category?
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.regularMaterial)
                .frame(width: 56, height: 56)
                .overlay(
                    Circle()
                        .stroke(category?.color.opacity(0.3) ?? Color.secondary.opacity(0.3), lineWidth: 2)
                )
            
            if let category = category {
                Image(systemName: category.safeIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(category.color)
            } else {
                Image(systemName: "questionmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .shadow(
            color: (category?.color ?? .secondary).opacity(0.2),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

// MARK: - Empty Search View
struct EmptySearchView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "Нет трат" : "Ничего не найдено")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                if !searchText.isEmpty {
                    Text("Попробуйте изменить запрос")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Statistics Card
struct StatisticCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.0)
                    .tint(Color.expensePurple)
                
                Text("Загрузка...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
        .animation(.easeInOut(duration: 0.2), value: UUID())
    }
}

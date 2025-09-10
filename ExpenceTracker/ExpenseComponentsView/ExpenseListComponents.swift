//
//  ExpenseListComponents.swift
//  ExpenseTracker
//
//  Created by Developer on 21/06/2025.
//

import SwiftUI

// MARK: - Recent Expenses View (МАКСИМАЛЬНО ПРОСТОЕ РЕШЕНИЕ)
struct RecentExpensesView: View {
    let expenses: [Expense]
    let onShowAll: () -> Void
    let onExpenseTap: (Expense) -> Void
    let onExpenseDelete: ((Expense) -> Void)?
    let onExpenseEdit: ((Expense) -> Void)?
    
    init(
        expenses: [Expense],
        onShowAll: @escaping () -> Void,
        onExpenseTap: @escaping (Expense) -> Void,
        onExpenseDelete: ((Expense) -> Void)? = nil,
        onExpenseEdit: ((Expense) -> Void)? = nil
    ) {
        self.expenses = expenses
        self.onShowAll = onShowAll
        self.onExpenseTap = onExpenseTap
        self.onExpenseDelete = onExpenseDelete
        self.onExpenseEdit = onExpenseEdit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Недавние траты")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: onShowAll) {
                    HStack(spacing: 4) {
                        Text("Все")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(Color.expensePurple)
                }
            }
            
            if expenses.isEmpty {
                EmptyExpensesView()
            } else {
                // ✅ УБИРАЕМ ВСЕ АНИМАЦИИ И СЛОЖНУЮ ЛОГИКУ
                VStack(spacing: 12) {
                    ForEach(Array(expenses.prefix(4)), id: \.identifier) { expense in
                        SimpleExpenseCard(
                            expense: expense,
                            onTap: { onExpenseTap(expense) },
                            onDelete: onExpenseDelete != nil ? {
                                // ✅ ПРЯМОЙ ВЫЗОВ БЕЗ ЗАДЕРЖЕК
                                onExpenseDelete!(expense)
                            } : nil,
                            onEdit: onExpenseEdit != nil ? { onExpenseEdit!(expense) } : nil
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Empty Expenses View
struct EmptyExpensesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 4) {
                Text("Пока нет трат")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Добавьте первую трату, чтобы начать отслеживание")
                    .font(.subheadline)
                    .foregroundColor(.secondary.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: .black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
}

// MARK: - Quick Actions View
struct AddActionsView: View {
    let onAddTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            QuickActionButton(
                icon: "plus.circle.fill",
                title: "Добавить",
                gradient: LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing),
                action: onAddTap
            )
            
            QuickActionButton(
                icon: "camera.fill",
                title: "Сканировать",
                gradient: LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing),
                action: {}
            )
            
            QuickActionButton(
                icon: "mic.fill",
                title: "Голос",
                gradient: LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                action: {}
            )
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(gradient))
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

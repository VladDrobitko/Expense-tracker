//
//  TodayExpensesView.swift - Упрощенный экран только сегодняшних трат
//  ExpenseTracker
//
//  Created by Developer on 24/06/2025.
//

import SwiftUI

// MARK: - Today Expenses View (упрощенный - только список и сумма)
struct TodayExpensesView: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Простой header с суммой
                todayHeader
                
                // Список трат за сегодня
                todayExpensesList
            }
            .navigationTitle("Сегодня")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.primary) // ✅ ИЗМЕНЕНО: на белый
                }
            }
            .refreshable {
                await appState.refreshData()
            }
        }
    }
    
    // MARK: - Simple Today Header (только сумма)
    private var todayHeader: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("ПОТРАЧЕНО СЕГОДНЯ")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                
                Text(appState.formatAmount(todayTotal))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary) // ✅ ИЗМЕНЕНО: на белый
            }
            
            if !todayExpenses.isEmpty {
                Text("\(todayExpenses.count) \(expenseCountLabel)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.regularMaterial)
    }
    
    // MARK: - Today Expenses List (карточки как на главном экране)
    private var todayExpensesList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(todayExpenses, id: \.identifier) { expense in
                    TodayExpenseCard(
                        expense: expense,
                        appState: appState,
                        onEdit: {
                            // TODO: Edit expense
                            print("Edit expense: \(expense.safeName)")
                        },
                        onDelete: {
                            Task {
                                await appState.deleteExpense(expense)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Computed Properties
    
    private var todayExpenses: [Expense] {
        let calendar = Calendar.current
        return appState.expenses.filter { calendar.isDateInToday($0.safeDate) }
            .sorted { $0.safeDate > $1.safeDate }
    }
    
    private var todayTotal: Double {
        todayExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var expenseCountLabel: String {
        switch todayExpenses.count {
        case 1: return "трата"
        case 2...4: return "траты"
        default: return "трат"
        }
    }
}

// MARK: - Today Expense Card (такая же как на главном экране)
struct TodayExpenseCard: View {
    let expense: Expense
    let appState: AppState
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingActionSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            if let category = expense.category {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(category.color.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: category.safeIcon)
                            .font(.system(size: 14))
                            .foregroundColor(category.color)
                    )
            } else {
                Circle()
                    .fill(.secondary.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "questionmark")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    )
            }
            
            // Expense info
            VStack(alignment: .leading, spacing: 6) { // ✅ УВЕЛИЧЕНО: с 2 до 4
                Text(expense.safeName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if let category = expense.category {
                        Text(category.safeName)
                            .font(.caption2)
                            .foregroundColor(category.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(category.color.opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .stroke(category.color.opacity(0.3), lineWidth: 0.5)
                                    )
                            )
                    }
                    
                    Text(expense.timeString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let notes = expense.notes, !notes.isEmpty {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(notes)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
            
            Spacer()
            
            // Amount
            Text(appState.formatAmount(expense.amount))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Menu button (как на главном экране)
            Button(action: { showingActionSheet = true }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16) // ✅ УВЕЛИЧЕНО: с 10 до 14 (+4 пикселя)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5) // ✅ Как у поиска
                )
        )
        .confirmationDialog("Действия", isPresented: $showingActionSheet) {
            Button("Изменить") {
                onEdit()
            }
            
            Button("Удалить", role: .destructive) {
                showingDeleteAlert = true
            }
            
            Button("Отмена", role: .cancel) { }
        }
        .alert("Удалить трату?", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Трата \"\(expense.safeName)\" на сумму \(appState.formatAmount(expense.amount)) будет удалена безвозвратно.")
        }
    }
}

#Preview("Today Expenses") {
    TodayExpensesView(appState: AppState.preview)
}

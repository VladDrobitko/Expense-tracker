//
//  HomeViewComponents.swift - ИСПРАВЛЕНЫ: кнопка "Добавить" и поиск
//  ExpenseTracker
//
//  Created by Developer on 24/06/2025.
//

import SwiftUI

// MARK: - Home Add Button (ИСПРАВЛЕНО: игнорирует клавиатуру)
struct HomeAddButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.bottom, 30)
        .padding(.trailing, 30)
        .ignoresSafeArea(.keyboard) // ✅ ИСПРАВЛЕНО: кнопка не двигается с клавиатурой
    }
}

// MARK: - Home Search Field (ИСПРАВЛЕНО: управление клавиатурой)
struct HomeSearchField: View {
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer().frame(height: 16)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                TextField("Поиск трат...", text: .constant(""))
                    .font(.subheadline)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .disabled(true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: 180)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
            .onTapGesture {
                action()
            }
        }
    }
}

// MARK: - Search View (НОВЫЙ: полноценный поиск с управлением клавиатуры)
struct SearchView: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var searchResults: [Expense] = []
    @State private var isSearching = false
    @FocusState private var isSearchFieldFocused: Bool // ✅ Для управления клавиатурой
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ✅ НОВЫЙ: Поисковая строка с правильным управлением
                searchHeader
                
                // Результаты поиска
                if searchText.isEmpty {
                    emptySearchView
                } else if searchResults.isEmpty && !isSearching {
                    noResultsView
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Поиск")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        hideKeyboard()
                        dismiss()
                    }
                    .foregroundColor(Color.primary)
                }
                
                // ✅ НОВАЯ: Кнопка "Готово" в тулбаре клавиатуры
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") {
                        hideKeyboard() // ✅ Эта только скрывает клавиатуру
                    }
                    .foregroundColor(Color.primary)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            // Автофокус на поле поиска
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isSearchFieldFocused = true
            }
        }
        .onChange(of: searchText) { newValue in
            performSearch(query: newValue)
        }
        // ✅ НОВОЕ: Скрытие клавиатуры по тапу на фон
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    // ✅ НОВЫЙ: Красивый header с поиском
    private var searchHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                
                TextField("Поиск по названию, заметкам...", text: $searchText)
                    .font(.body)
                    .focused($isSearchFieldFocused) // ✅ Привязка к FocusState
                    .submitLabel(.search)
                    .onSubmit {
                        performSearch(query: searchText)
                    }
                
                if !searchText.isEmpty {
                    Button(action: clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSearchFieldFocused ? Color.expensePurple : Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isSearchFieldFocused)
            
            if isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial)
    }
    
    private var emptySearchView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text("Поиск по тратам")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Введите название траты или заметку\nдля поиска в вашей истории")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text("Ничего не найдено")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Попробуйте изменить запрос\nили проверьте правильность написания")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private var searchResultsList: some View {
        List {
            Section {
                ForEach(searchResults, id: \.identifier) { expense in
                    SearchResultRow(expense: expense, appState: appState, searchText: searchText)
                }
            } header: {
                Text("Найдено: \(searchResults.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Actions
    
    private func performSearch(query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        // Простой поиск по названию и заметкам
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // Имитация задержки
            searchResults = appState.expenses.filter { expense in
                expense.safeName.localizedCaseInsensitiveContains(trimmedQuery) ||
                (expense.notes?.localizedCaseInsensitiveContains(trimmedQuery) ?? false)
            }
            .sorted { $0.safeDate > $1.safeDate }
            
            isSearching = false
        }
    }
    
    private func clearSearch() {
        searchText = ""
        searchResults = []
        isSearchFieldFocused = true
    }
    
    private func hideKeyboard() {
        isSearchFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let expense: Expense
    let appState: AppState
    let searchText: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            if let category = expense.category {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 36, height: 36)
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
            VStack(alignment: .leading, spacing: 4) {
                Text(highlightedText(expense.safeName, highlight: searchText))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let category = expense.category {
                        Text(category.safeName)
                            .font(.caption2)
                            .foregroundColor(category.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(category.color.opacity(0.1))
                            )
                    }
                    
                    Text(expense.dateString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let notes = expense.notes, !notes.isEmpty,
                   notes.localizedCaseInsensitiveContains(searchText) {
                    Text(highlightedText(notes, highlight: searchText))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Amount
            Text(appState.formatAmount(expense.amount))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
    
    private func highlightedText(_ text: String, highlight: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        if let range = text.range(of: highlight, options: .caseInsensitive) {
            let nsRange = NSRange(range, in: text)
            if let attributedRange = Range(nsRange, in: attributedString) {
                attributedString[attributedRange].backgroundColor = Color.expensePurple.opacity(0.3)
                attributedString[attributedRange].foregroundColor = Color.expensePurple
            }
        }
        
        return attributedString
    }
}

// MARK: - Home Amount Card (floating over gradient)
struct HomeAmountCard: View {
    let amount: Double
    let expenseCount: Int
    let lastExpense: Expense?
    let appState: AppState
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("ПОТРАЧЕНО СЕГОДНЯ")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ?
                        .white.opacity(0.8) :
                        .white.opacity(0.9))
                    .tracking(0.5)
                
                Text(appState.formatAmount(amount))
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.expensePurple.opacity(colorScheme == .dark ? 0.3 : 0.4), radius: 8, x: 0, y: 2)
                    .minimumScaleFactor(0.8)
                
                contextInfo
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    private var contextInfo: some View {
        HStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("\(expenseCount)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(expenseCountLabel)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Rectangle()
                .fill(.white.opacity(0.3))
                .frame(width: 1, height: 24)
            
            VStack(spacing: 4) {
                if let comparison = yesterdayComparison {
                    HStack(spacing: 4) {
                        Image(systemName: comparison.isMore ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(comparison.isMore ? .red : .green)
                        
                        Text(comparison.text)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text("чем вчера")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Text("Первый день")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("отслеживания")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    
    // MARK: - Yesterday Comparison
    private var yesterdayComparison: (isMore: Bool, text: String)? {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return nil }
        
        // Траты за вчера
        let yesterdayExpenses = appState.expenses.filter { expense in
            calendar.isDate(expense.safeDate, inSameDayAs: yesterday)
        }
        
        guard !yesterdayExpenses.isEmpty else { return nil }
        
        let yesterdayTotal = yesterdayExpenses.reduce(0) { $0 + $1.amount }
        let todayTotal = amount
        
        if todayTotal > yesterdayTotal {
            let difference = todayTotal - yesterdayTotal
            return (true, "на \(appState.formatAmount(difference)) больше")
        } else if todayTotal < yesterdayTotal {
            let difference = yesterdayTotal - todayTotal
            return (false, "на \(appState.formatAmount(difference)) меньше")
        } else {
            return (false, "как вчера")
        }
    }
    
    private var expenseCountLabel: String {
        switch expenseCount {
        case 0: return "трат нет"
        case 1: return "трата"
        case 2...4: return "траты"
        default: return "трат"
        }
    }
}

// MARK: - Home Action Buttons
struct HomeActionButtons: View {
    let onQuickActionsTap: () -> Void
    let onStatsTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            HomeActionButton(
                title: "Быстрые действия",
                subtitle: "Шаблоны и подписки",
                icon: "bolt.fill",
                iconColor: .orange,
                action: onQuickActionsTap
            )
            
            HomeActionButton(
                title: "Статистика",
                subtitle: "Аналитика и тренды",
                icon: "chart.bar.fill",
                iconColor: .blue,
                action: onStatsTap
            )
        }
    }
}

// MARK: - Home Action Button
struct HomeActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(iconColor.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5) // ✅ Как у поиска
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Home Today Section
struct HomeTodaySection: View {
    let expenses: [Expense]
    let appState: AppState
    let colorScheme: ColorScheme
    let onShowAll: () -> Void
    let onAddFirst: () -> Void
    let onExpenseEdit: (Expense) -> Void
    let onExpenseDelete: (Expense) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Сегодня")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !expenses.isEmpty {
                    Button(action: onShowAll) {
                        HStack(spacing: 4) {
                            Text("Все")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            if expenses.isEmpty {
                HomeTodayEmptyView()
            } else {
                VStack(spacing: 8) {
                    ForEach(expenses.prefix(5), id: \.identifier) { expense in
                        HomeExpenseRow(
                            expense: expense,
                            appState: appState,
                            onEdit: { onExpenseEdit(expense) },
                            onDelete: { onExpenseDelete(expense) }
                        )
                    }
                }
            }
        }
        .padding(.vertical, 24)
        // ✅ УБРАЛИ черный фон чтобы не было видно при скролле на градиенте
    }
}

// MARK: - Home Today Empty View
struct HomeTodayEmptyView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 4) {
                Text("Пока нет трат")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Добавьте первую трату с помощью кнопки ниже")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Home Expense Row
struct HomeExpenseRow: View {
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
            VStack(alignment: .leading, spacing: 6) {
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
                }
            }
            
            Spacer()
            
            // Amount
            Text(appState.formatAmount(expense.amount))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Menu button
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
        .padding(.vertical, 16)
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

// MARK: - Home Profile Button

struct HomeProfileButton: View {
    let appState: AppState
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer().frame(height: 16)
            
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.white)
                            .frame(width: 16, height: 2)
                        
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.white)
                            .frame(width: 16, height: 2)
                        
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.white)
                            .frame(width: 16, height: 2)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Home Background (без изменений)
struct HomeBackgroundView: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        ZStack {
            // Base background
            (colorScheme == .dark ?
                Color(.systemBackground) :
                Color(.systemGray6).opacity(0.5))
                .ignoresSafeArea()
            
            // Revolut-style gradient
            GeometryReader { _ in
                let screenHeight = UIScreen.main.bounds.height
                let gradientHeight = screenHeight * 0.55
                
                VStack {
                    LinearGradient(
                        colors: colorScheme == .dark ? [
                            Color.expensePurple.opacity(0.18),
                            Color.expenseBlue.opacity(0.08),
                            Color.clear
                        ] : [
                            Color.expensePurple.opacity(0.35),
                            Color.expenseBlue.opacity(0.20),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: gradientHeight)
                    .mask(
                        LinearGradient(
                            colors: [
                                Color.black,
                                Color.black,
                                Color.black,
                                Color.black.opacity(0.9),
                                Color.black.opacity(0.7),
                                Color.black.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(gradientOrbs)
                    
                    Spacer()
                }
            }
            .ignoresSafeArea(.all)
        }
    }
    
    private var gradientOrbs: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.expensePurple.opacity(colorScheme == .dark ? 0.25 : 0.4),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: -100, y: -80)
                .blur(radius: 50)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.expenseBlue.opacity(colorScheme == .dark ? 0.2 : 0.35),
                            Color.clear
                        ],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 280, height: 280)
                .offset(x: 120, y: -20)
                .blur(radius: 70)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.expensePurple.opacity(colorScheme == .dark ? 0.15 : 0.25),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 200, height: 200)
                .offset(x: 0, y: 60)
                .blur(radius: 40)
        }
    }
}

#Preview("Search View") {
    SearchView(appState: AppState.preview)
}

#Preview("Home Add Button") {
    ZStack {
        HomeBackgroundView(colorScheme: .light)
        VStack {
            Spacer()
            HomeAddButton(action: {})
        }
        .padding()
    }
}

#Preview("Home Search Field") {
    ZStack {
        HomeBackgroundView(colorScheme: .dark)
        HomeSearchField(action: {})
    }
}

#Preview("Home Amount Card - Light") {
    ZStack {
        HomeBackgroundView(colorScheme: .light)
        HomeAmountCard(
            amount: 1234.56,
            expenseCount: 3,
            lastExpense: AppState.preview.expenses.first,
            appState: AppState.preview,
            colorScheme: .light
        )
        .padding()
    }
}

#Preview("Home Amount Card - Dark") {
    ZStack {
        HomeBackgroundView(colorScheme: .dark)
        HomeAmountCard(
            amount: 987.65,
            expenseCount: 5,
            lastExpense: AppState.preview.expenses.first,
            appState: AppState.preview,
            colorScheme: .dark
        )
        .padding()
    }
}

#Preview("Home Action Buttons") {
    ZStack {
        HomeBackgroundView(colorScheme: .light)
        HomeActionButtons(onQuickActionsTap: {}, onStatsTap: {})
            .padding()
    }
}

#Preview("Home Today Section - Empty") {
    ZStack {
        HomeBackgroundView(colorScheme: .light)
        ScrollView {
            HomeTodaySection(
                expenses: [],
                appState: AppState.preview,
                colorScheme: .light,
                onShowAll: {},
                onAddFirst: {},
                onExpenseEdit: { _ in },
                onExpenseDelete: { _ in }
            )
            .padding()
        }
    }
}

#Preview("Home Today Section - Filled") {
    ZStack {
        HomeBackgroundView(colorScheme: .dark)
        ScrollView {
            HomeTodaySection(
                expenses: Array(AppState.preview.expenses.prefix(5)),
                appState: AppState.preview,
                colorScheme: .dark,
                onShowAll: {},
                onAddFirst: {},
                onExpenseEdit: { _ in },
                onExpenseDelete: { _ in }
            )
            .padding()
        }
    }
}

#Preview("Home Profile Button") {
    ZStack {
        HomeBackgroundView(colorScheme: .dark)
        HomeProfileButton(appState: AppState.preview, action: {})
    }
}

#Preview("Home Background View - Both") {
    VStack(spacing: 0) {
        HomeBackgroundView(colorScheme: .light)
            .frame(height: 200)
        HomeBackgroundView(colorScheme: .dark)
            .frame(height: 200)
    }
}


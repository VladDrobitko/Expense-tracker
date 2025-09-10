//
//  AddExpenseSheet.swift
//  ExpenseTracker
//
//  Created by Developer on 24/06/2025.
//

import SwiftUI

// MARK: - Add Expense Sheet (обновлён под AppState)
struct AddExpenseSheet: View {
    let appState: AppState // Принимаем AppState напрямую
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingManualInput = false
    @State private var showingReceiptScanner = false
    @State private var showingVoiceInput = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Заголовок
                VStack(spacing: 16) {
                    Text("Добавить трату")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    Text("Выберите способ добавления")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 32)
                
                // Быстрые действия в модальном окне
                VStack(spacing: 20) {
                    // Ручное добавление
                    AddMethodButton(
                        icon: "plus.circle.fill",
                        title: "Ввести вручную",
                        subtitle: "Введите сумму и выберите категорию",
                        gradient: LinearGradient(colors: [Color.expensePurple, Color.expenseBlue], startPoint: .topLeading, endPoint: .bottomTrailing),
                        isEnabled: true
                    ) {
                        showingManualInput = true
                    }
                    
                    // Сканирование (заглушка, но с улучшенным UI)
                    AddMethodButton(
                        icon: "camera.fill",
                        title: "Сканировать чек",
                        subtitle: "Скоро будет доступно",
                        gradient: LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing),
                        isEnabled: false
                    ) {
                        showComingSoonAlert(feature: "сканирование чеков")
                    }
                    
                    // Голосовой ввод (заглушка, но с улучшенным UI)
                    AddMethodButton(
                        icon: "mic.fill",
                        title: "Голосовой ввод",
                        subtitle: "Скоро будет доступно",
                        gradient: LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                        isEnabled: false
                    ) {
                        showComingSoonAlert(feature: "голосовой ввод")
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .presentationDetents([.fraction(0.6)])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingManualInput) {
            ManualExpenseInputSheet(appState: appState) // Передаём AppState
        }
        .alert("Скоро будет доступно", isPresented: $showingReceiptScanner) {
            Button("OK") { }
        } message: {
            Text("Функция сканирования чеков будет добавлена в следующих обновлениях.")
        }
        .alert("Скоро будет доступно", isPresented: $showingVoiceInput) {
            Button("OK") { }
        } message: {
            Text("Функция голосового ввода будет добавлена в следующих обновлениях.")
        }
    }
    
    private func showComingSoonAlert(feature: String) {
        if feature.contains("сканирование") {
            showingReceiptScanner = true
        } else if feature.contains("голосовой") {
            showingVoiceInput = true
        }
    }
}

// MARK: - Add Method Button (улучшен)
struct AddMethodButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: LinearGradient
    let isEnabled: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Иконка
                ZStack {
                    Circle()
                        .fill(isEnabled ? gradient : LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isEnabled ? .white : .gray)
                }
                
                // Текст
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isEnabled ? .primary : .secondary)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Стрелка или индикатор
                Group {
                    if isEnabled {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "clock")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isEnabled ? .regularMaterial : .ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(colorScheme == .dark ? 0.1 : 0.2), lineWidth: 1)
                    )
            )
            .opacity(isEnabled ? 1.0 : 0.7)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - Manual Expense Input Sheet (полностью обновлён под AppState)
struct ManualExpenseInputSheet: View {
    let appState: AppState // Принимаем AppState напрямую
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount: String = ""
    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var selectedCategory: Category?
    @State private var selectedDate = Date()
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Валидация в реальном времени
    @State private var amountError: String?
    @State private var nameError: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Поле суммы с валидацией
                    amountSection
                    
                    // Название с валидацией
                    nameSection
                    
                    // Категория с улучшенным UI
                    categorySection
                    
                    // Заметки
                    notesSection
                    
                    // Дата с умными кнопками
                    dateSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") {
                        hideKeyboard()
                    }
                    .foregroundColor(Color.primary)
                    .fontWeight(.semibold)
                }
            }
            .navigationTitle("Добавить трату")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(Color.secondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        Task {
                            await addExpense()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                    .foregroundColor(isFormValid ? Color.primary : .secondary)
                    .fontWeight(.semibold)
                }
            }
            .alert("Ошибка", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .overlay(
                Group {
                    if isLoading {
                        LoadingOverlay()
                    }
                }
            )
        }
        .onAppear {
            // Устанавливаем дефолтную дату как выбранную в AppState
            selectedDate = appState.selectedDate
            
            // Предвыбираем первую категорию если есть
            if selectedCategory == nil, let firstCategory = appState.categories.first {
                selectedCategory = firstCategory
            }
        }
    }
    
    // MARK: - Amount Section
    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Сумма")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(appState.userSettings.currency.symbol) // Используем настоящую валюту!
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("0.00", text: $amount)
                        .font(.system(size: 24, weight: .medium))
                        .keyboardType(.decimalPad)
                        .onChange(of: amount) { _ in
                            validateAmount()
                        }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(amountError != nil ? .red : .clear, lineWidth: 1)
                        )
                )
                
                if let error = amountError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Name Section
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Название")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("Например: Кофе в Starbucks", text: $name)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.regularMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(nameError != nil ? .red : .clear, lineWidth: 1)
                            )
                    )
                    .onChange(of: name) { _ in
                        validateName()
                    }
                
                if let error = nameError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Category Section (улучшен)
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Категория")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if appState.categories.isEmpty {
                    Button("Создать категорию") {
                        // TODO: Открыть создание категории
                        print("Create category tapped")
                    }
                    .font(.caption)
                    .foregroundColor(Color.expensePurple)
                }
            }
            
            if appState.categories.isEmpty {
                EmptyCategoriesView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(appState.categories, id: \.identifier) { category in
                            CategorySelectionButton(
                                category: category,
                                isSelected: selectedCategory?.identifier == category.identifier
                            ) {
                                selectedCategory = category
                                
                                // Haptic feedback
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Заметки (необязательно)")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("Дополнительная информация", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                )
        }
    }
    
    // MARK: - Date Section (улучшен)
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Дата")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Быстрый выбор даты
            HStack(spacing: 8) {
                QuickDateButton(title: "Сегодня", isSelected: Calendar.current.isDateInToday(selectedDate)) {
                    selectedDate = Date()
                }
                
                QuickDateButton(title: "Вчера", isSelected: Calendar.current.isDateInYesterday(selectedDate)) {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                }
                
                QuickDateButton(title: "Позавчера", isSelected: isDayBeforeYesterday(selectedDate)) {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
                }
                
                Spacer()
            }
            
            // Основной выбор даты
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 18))
                    .foregroundColor(Color.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatSelectedDate())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(formatRelativeDate())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                    .labelsHidden()
                    .colorMultiply(Color.primary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard selectedCategory != nil else { return false }
        guard amountError == nil && nameError == nil else { return false }
        return true
    }
    
    // MARK: - Actions
    
    private func addExpense() async {
        guard let amountValue = Double(amount),
              let category = selectedCategory else {
            errorMessage = "Проверьте правильность заполнения полей"
            return
        }
        
        isLoading = true
        
        let success = await appState.addExpense( // Используем AppState напрямую!
            amount: amountValue,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.isEmpty ? nil : notes,
            categoryId: category.identifier,
            date: selectedDate
        )
        
        isLoading = false
        
        if success {
            // Haptic feedback для успеха
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            
            dismiss()
        } else {
            // Haptic feedback для ошибки
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
            
            errorMessage = "Не удалось добавить трату. Попробуйте еще раз."
        }
    }
    
    // MARK: - Validation
    
    private func validateAmount() {
        let trimmedAmount = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedAmount.isEmpty {
            amountError = nil
            return
        }
        
        guard let value = Double(trimmedAmount) else {
            amountError = "Введите корректную сумму"
            return
        }
        
        if value <= 0 {
            amountError = "Сумма должна быть больше нуля"
            return
        }
        
        if value > 1_000_000 {
            amountError = "Сумма слишком большая"
            return
        }
        
        amountError = nil
    }
    
    private func validateName() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty && !name.isEmpty {
            nameError = "Название не может состоять только из пробелов"
            return
        }
        
        if trimmedName.count > 100 {
            nameError = "Название слишком длинное"
            return
        }
        
        nameError = nil
    }
    
    // MARK: - Helper Methods
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func formatSelectedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: selectedDate)
    }
    
    private func formatRelativeDate() -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(selectedDate) {
            return "Сегодня"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Вчера"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Завтра"
        } else if isDayBeforeYesterday(selectedDate) {
            return "Позавчера"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "ru_RU")
            return formatter.string(from: selectedDate).capitalized
        }
    }
    
    private func isDayBeforeYesterday(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dayBeforeYesterday = calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        return calendar.isDate(date, inSameDayAs: dayBeforeYesterday)
    }
}

// MARK: - Empty Categories View
struct EmptyCategoriesView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 4) {
                Text("Нет категорий")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text("Создайте категории для организации трат")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.8))
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
                        .stroke(.secondary.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Quick Date Button (улучшен)
struct QuickDateButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? .white : Color.expensePurple)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.expensePurple : Color.expensePurple.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Add Expense Sheet") {
    AddExpenseSheet(appState: AppState.preview)
}

#Preview("Manual Input") {
    ManualExpenseInputSheet(appState: AppState.preview)
}

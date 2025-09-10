//
//  CategoryManagementView.swift
//  ExpenseTracker
//
//  Created by Developer on 24/06/2025.
//

import SwiftUI

// MARK: - Category Management View (ПОЛНОСТЬЮ обновлён под AppState)
struct CategoryManagementView: View {
    @EnvironmentObject var appState: AppState // ✅ Используем AppState из Environment
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddCategory = false
    @State private var showingEditCategory: Category?
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: Category?
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    loadingView
                } else if appState.categories.isEmpty { // ✅ Используем appState.categories
                    emptyStateView
                } else {
                    categoriesList
                }
            }
            .navigationTitle("Категории")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Готово") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCategory = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(Color.expensePurple)
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView(appState: appState) // ✅ Передаём appState
            }
            .sheet(item: $showingEditCategory) { category in
                EditCategoryView(category: category, appState: appState) // ✅ Передаём appState
            }
            .alert("Удалить категорию?", isPresented: $showingDeleteAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Удалить", role: .destructive) {
                    if let category = categoryToDelete {
                        deleteCategory(category)
                    }
                }
            } message: {
                if let category = categoryToDelete {
                    Text("Категория \"\(category.safeName)\" будет удалена. Все связанные траты останутся без категории.")
                }
            }
            .onAppear {
                // ✅ Данные уже загружены в AppState
                print("📁 CategoryManagementView appeared")
            }
            .refreshable {
                await appState.refreshData() // ✅ Используем appState
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Загрузка категорий...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary.opacity(0.5))
                    .symbolRenderingMode(.hierarchical)
                
                VStack(spacing: 8) {
                    Text("Нет категорий")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Создайте первую категорию\nдля организации трат")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Button {
                showingAddCategory = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Добавить категорию")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.expensePurple, Color.expenseBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Categories List
    private var categoriesList: some View {
        List {
            Section {
                ForEach(appState.categories, id: \.identifier) { category in // ✅ Используем appState.categories
                    CategoryRowView(
                        category: category,
                        appState: appState, // ✅ Передаём appState для статистики
                        onEdit: { showingEditCategory = category },
                        onDelete: {
                            categoryToDelete = category
                            showingDeleteAlert = true
                        }
                    )
                }
                .onMove(perform: moveCategories)
            } header: {
                HStack {
                    Text("Мои категории")
                    Spacer()
                    Text("\(appState.categories.count)") // ✅ Используем appState.categories
                        .foregroundColor(.secondary)
                }
            } footer: {
                Text("Потяните категорию для изменения порядка. Смахните влево для действий.")
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Actions
    private func moveCategories(from source: IndexSet, to destination: Int) {
        var updatedCategories = appState.categories // ✅ Используем appState.categories
        updatedCategories.move(fromOffsets: source, toOffset: destination)
        
        Task {
            // TODO: Добавить reorderCategories в AppState
            print("🔄 Categories reordered")
        }
    }
    
    private func deleteCategory(_ category: Category) {
        Task {
            let success = await appState.deleteCategory(category) // ✅ Используем appState
            if success {
                print("✅ Category deleted successfully")
            } else {
                print("❌ Failed to delete category")
            }
        }
    }
}

// MARK: - Category Row View (обновлён под AppState)
struct CategoryRowView: View {
    let category: Category
    let appState: AppState // ✅ Принимаем AppState для статистики
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var expenseCount: Int = 0
    @State private var totalAmount: Double = 0
    @State private var isLoadingStats = true
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: category.safeIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(category.color)
            }
            
            // Category Info
            VStack(alignment: .leading, spacing: 4) {
                Text(category.safeName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if isLoadingStats {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Загрузка...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 12) {
                        Text(expenseCountText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if totalAmount > 0 {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(appState.formatAmount(totalAmount)) // ✅ Используем правильную валюту!
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(category.color)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Edit Button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(.quaternary))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Удалить", systemImage: "trash")
            }
            
            Button(action: onEdit) {
                Label("Изменить", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .task {
            await loadCategoryStats()
        }
    }
    
    private var expenseCountText: String {
        switch expenseCount {
        case 0:
            return "Нет трат"
        case 1:
            return "1 трата"
        case 2...4:
            return "\(expenseCount) траты"
        default:
            return "\(expenseCount) трат"
        }
    }
    
    @MainActor
    private func loadCategoryStats() async {
        // ✅ Вычисляем статистику из AppState вместо создания нового менеджера
        let categoryExpenses = appState.expenses.filter { expense in
            expense.category?.identifier == category.identifier
        }
        
        expenseCount = categoryExpenses.count
        totalAmount = categoryExpenses.reduce(0) { $0 + $1.amount }
        isLoadingStats = false
    }
}

// MARK: - Add Category View (обновлён под AppState)
struct AddCategoryView: View {
    let appState: AppState // ✅ Принимаем AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "questionmark"
    @State private var selectedColor: Color = .blue
    @State private var isLoading = false
    
    // Validation
    @State private var nameError: String?
    
    private let availableIcons = [
        "fork.knife", "car.fill", "house.fill", "bag.fill", "tv.fill",
        "heart.fill", "book.fill", "airplane", "gamecontroller.fill",
        "music.note", "camera.fill", "gift.fill", "cart.fill", "creditcard.fill",
        "pills.fill", "dumbbell", "pawprint.fill", "leaf.fill", "cup.and.saucer.fill",
        "tshirt.fill", "fuelpump.fill", "stethoscope", "graduationcap.fill", "bus.fill"
    ]
    
    private let availableColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink, .brown, .gray
    ]
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && nameError == nil
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Preview Section
                    previewSection
                    
                    // Name Section
                    nameSection
                    
                    // Icon Section
                    iconSection
                    
                    // Color Section
                    colorSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Новая категория")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveCategory()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? Color.expensePurple : .secondary)
                    .disabled(!isFormValid || isLoading)
                }
            }
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.1))
                    }
                }
            )
        }
    }
    
    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(spacing: 16) {
            Text("Предварительный просмотр")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(selectedColor.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: selectedIcon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(selectedColor)
                }
                
                Text(name.isEmpty ? "Название категории" : name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(name.isEmpty ? .secondary : .primary)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Name Section
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Название")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("Например: Кафе и рестораны", text: $name)
                    .textFieldStyle(.roundedBorder)
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
    
    // MARK: - Icon Section
    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Иконка")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(availableIcons, id: \.self) { icon in
                    Button(action: { selectedIcon = icon }) {
                        ZStack {
                            Circle()
                                .fill(selectedIcon == icon ? selectedColor.opacity(0.2) : Color(.systemGray6))
                                .frame(width: 44, height: 44)
                            
                            if selectedIcon == icon {
                                Circle()
                                    .stroke(selectedColor, lineWidth: 2)
                                    .frame(width: 44, height: 44)
                            }
                            
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(selectedIcon == icon ? selectedColor : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Color Section
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Цвет")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(availableColors, id: \.description) { color in
                    Button(action: { selectedColor = color }) {
                        ZStack {
                            Circle()
                                .fill(color)
                                .frame(width: 36, height: 36)
                            
                            if selectedColor.description == color.description {
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                                    .frame(width: 36, height: 36)
                                
                                Circle()
                                    .stroke(.black.opacity(0.2), lineWidth: 1)
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Methods
    private func validateName() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            nameError = nil // Allow empty for real-time validation
        } else if trimmedName.count > 30 {
            nameError = "Название слишком длинное (максимум 30 символов)"
        } else {
            nameError = nil
        }
    }
    
    private func saveCategory() {
        guard isFormValid else { return }
        
        isLoading = true
        
        Task {
            let success = await appState.addCategory( // ✅ Используем appState
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                icon: selectedIcon,
                color: selectedColor
            )
            
            await MainActor.run {
                isLoading = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Edit Category View (обновлён под AppState)
struct EditCategoryView: View {
    let category: Category
    let appState: AppState // ✅ Принимаем AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedIcon: String = ""
    @State private var selectedColor: Color = .blue
    @State private var isLoading = false
    
    // Validation
    @State private var nameError: String?
    
    private let availableIcons = [
        "fork.knife", "car.fill", "house.fill", "bag.fill", "tv.fill",
        "heart.fill", "book.fill", "airplane", "gamecontroller.fill",
        "music.note", "camera.fill", "gift.fill", "cart.fill", "creditcard.fill",
        "pills.fill", "dumbbell", "pawprint.fill", "leaf.fill", "cup.and.saucer.fill",
        "tshirt.fill", "fuelpump.fill", "stethoscope", "graduationcap.fill", "bus.fill"
    ]
    
    private let availableColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink, .brown, .gray
    ]
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && nameError == nil
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Preview Section
                    previewSection
                    
                    // Name Section
                    nameSection
                    
                    // Icon Section
                    iconSection
                    
                    // Color Section
                    colorSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Изменить категорию")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? Color.expensePurple : .secondary)
                    .disabled(!isFormValid || isLoading)
                }
            }
            .onAppear {
                loadCategoryData()
            }
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.1))
                    }
                }
            )
        }
    }
    
    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(spacing: 16) {
            Text("Предварительный просмотр")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(selectedColor.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: selectedIcon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(selectedColor)
                }
                
                Text(name.isEmpty ? "Название категории" : name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(name.isEmpty ? .secondary : .primary)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Name Section
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Название")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("Например: Кафе и рестораны", text: $name)
                    .textFieldStyle(.roundedBorder)
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
    
    // MARK: - Icon Section
    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Иконка")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(availableIcons, id: \.self) { icon in
                    Button(action: { selectedIcon = icon }) {
                        ZStack {
                            Circle()
                                .fill(selectedIcon == icon ? selectedColor.opacity(0.2) : Color(.systemGray6))
                                .frame(width: 44, height: 44)
                            
                            if selectedIcon == icon {
                                Circle()
                                    .stroke(selectedColor, lineWidth: 2)
                                    .frame(width: 44, height: 44)
                            }
                            
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(selectedIcon == icon ? selectedColor : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Color Section
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Цвет")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(availableColors, id: \.description) { color in
                    Button(action: { selectedColor = color }) {
                        ZStack {
                            Circle()
                                .fill(color)
                                .frame(width: 36, height: 36)
                            
                            if selectedColor.description == color.description {
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                                    .frame(width: 36, height: 36)
                                
                                Circle()
                                    .stroke(.black.opacity(0.2), lineWidth: 1)
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Methods
    private func loadCategoryData() {
        name = category.safeName
        selectedIcon = category.safeIcon
        selectedColor = category.color
    }
    
    private func validateName() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            nameError = nil // Allow empty for real-time validation
        } else if trimmedName.count > 30 {
            nameError = "Название слишком длинное (максимум 30 символов)"
        } else {
            nameError = nil
        }
    }
    
    private func saveChanges() {
        guard isFormValid else { return }
        
        isLoading = true
        
        Task {
            let success = await appState.updateCategory( // ✅ Используем appState
                category,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                icon: selectedIcon,
                color: selectedColor
            )
            
            await MainActor.run {
                isLoading = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

#Preview("Category Management") {
    CategoryManagementView()
        .environmentObject(AppState.preview) // ✅ Добавляем AppState в Preview
}

#Preview("Add Category") {
    AddCategoryView(appState: AppState.preview) // ✅ Передаём AppState в Preview
}

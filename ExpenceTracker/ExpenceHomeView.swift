//
//  ExpenseHomeView.swift - ПРОСТОЕ переключение экранов с анимацией слева
//  ExpenseTracker
//
//  Created by Developer on 24/06/2025.
//

import SwiftUI

struct ExpenseHomeView: View {
    // MARK: - Dependencies
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ExpenseViewModel.standard()
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText: String = ""
    
    var body: some View {
        ZStack {
            // ✅ ГЛАВНЫЙ ЭКРАН - показываем когда профиль закрыт
            if !viewModel.showingProfile {
                mainScreen
                    .transition(.move(edge: .trailing)) // Главный экран уходит вправо
                .sheet(isPresented: $viewModel.showingSearch) {
            SearchView(appState: appState) // ✅ Новый SearchView с управлением клавиатуры
        }
    }
            
            // ✅ ЭКРАН ПРОФИЛЯ - показываем когда профиль открыт
            if viewModel.showingProfile {
                ProfileView(appState: appState) {
                    // Closure для закрытия профиля
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.hideProfile()
                    }
                }
                .transition(.move(edge: .leading)) // Профиль приходит слева
            }
        }
        .sheet(isPresented: $viewModel.showingAddExpense) {
            AddExpenseSheet(appState: appState)
        }
        .sheet(isPresented: $viewModel.showingTodayExpenses) {
            TodayExpensesView(appState: appState) // ✅ Только сегодняшние траты
        }
        .sheet(isPresented: $viewModel.showingAllExpenses) {
            StatisticsView(appState: appState) // ✅ Полная статистика
        }
        .sheet(isPresented: $viewModel.showingQuickActions) {
            QuickActionsView(appState: appState)
        }
    }
    
    // MARK: - Main Screen (вынесли в отдельный var)
    private var mainScreen: some View {
        NavigationStack {
            ZStack {
                // Background
                HomeBackgroundView(colorScheme: colorScheme)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Navigation bar compensation
                        Color.clear.frame(height: 20)
                        
                        // Main amount area
                        HomeAmountCard(
                            amount: appState.todaySpent,
                            expenseCount: todayExpenses.count,
                            lastExpense: todayExpenses.first,
                            appState: appState,
                            colorScheme: colorScheme
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Action buttons
                        HomeActionButtons {
                            viewModel.showQuickActions()
                        } onStatsTap: {
                            viewModel.showAllExpenses()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        
                        // Today expenses
                        HomeTodaySection(
                            expenses: todayExpenses,
                            appState: appState,
                            colorScheme: colorScheme,
                            onShowAll: { viewModel.showTodayExpenses() },
                            onAddFirst: { viewModel.showAddExpense() },
                            onExpenseEdit: { expense in
                                // TODO: Edit expense
                            },
                            onExpenseDelete: { expense in
                                Task { await appState.deleteExpense(expense) }
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        .padding(.bottom, 120)
                    }
                }
                .refreshable {
                    await appState.refreshData()
                }
                
                // Floating add button
                VStack {
                    Spacer()
                    HomeAddButton {
                        viewModel.showAddExpense()
                    }
                }
            }
// Removed .searchable and .onSubmit modifiers here
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if viewModel.showingProfile {
                                viewModel.hideProfile()
                            } else {
                                viewModel.showProfile()
                            }
                        }
                    }) {
                        Image(systemName: viewModel.showingProfile ? "house.fill" : "house")
                            .imageScale(.large)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showSearch()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .imageScale(.large)
                    }
                }
            }
            .onAppear {
                viewModel.setupUIReactions()
                setupTransparentNavigationBar()
            }
        }
    }
    
    // MARK: - Computed Properties
    private var todayExpenses: [Expense] {
        let calendar = Calendar.current
        return appState.expenses.filter { calendar.isDateInToday($0.safeDate) }
            .sorted { $0.safeDate > $1.safeDate }
    }
    
    // MARK: - Navigation Setup
    private func setupTransparentNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ExpenseHomeView()
        .environmentObject(AppState.preview)
}

#Preview("Dark") {
    ExpenseHomeView()
        .environmentObject(AppState.preview)
        .preferredColorScheme(.dark)
}


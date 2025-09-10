//
//  CurrencySelectionView.swift - Enhanced with full functionality
//  ExpenseTracker
//
//  Created by Developer on 24/06/2025.
//

import SwiftUI

// MARK: - Enhanced Currency Selection View
struct CurrencySelectionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var showingConfirmation = false
    @State private var selectedCurrency: Currency?
    
    // Filtered currencies based on search
    private var filteredCurrencies: [Currency] {
        if searchText.isEmpty {
            return Currency.allCases
        } else {
            return Currency.allCases.filter { currency in
                currency.name.localizedCaseInsensitiveContains(searchText) ||
                currency.rawValue.localizedCaseInsensitiveContains(searchText) ||
                currency.symbol.contains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchSection
                
                // Currency List
                currencyList
                
                // Current Selection Footer
                if !searchText.isEmpty {
                    currentSelectionFooter
                }
            }
            .navigationTitle("Валюта")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .overlay(
                Group {
                    if isLoading {
                        LoadingOverlay()
                    }
                }
            )
            .alert("Изменить валюту?", isPresented: $showingConfirmation) {
                Button("Отмена", role: .cancel) {
                    selectedCurrency = nil
                }
                Button("Изменить") {
                    if let currency = selectedCurrency {
                        changeCurrency(to: currency)
                    }
                }
            } message: {
                if let currency = selectedCurrency {
                    Text("Валюта будет изменена на \(currency.name). Это повлияет на отображение всех сумм в приложении.")
                }
            }
        }
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                TextField("Поиск валют...", text: $searchText)
                    .font(.body)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
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
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Divider()
                .padding(.top, 16)
        }
    }
    
    // MARK: - Currency List
    private var currencyList: some View {
        List {
            if filteredCurrencies.isEmpty {
                emptySearchResults
            } else {
                ForEach(filteredCurrencies, id: \.rawValue) { currency in
                    CurrencyRowView(
                        currency: currency,
                        isSelected: appState.userSettings.currency == currency,
                        isCurrentlyUsed: appState.userSettings.currency == currency
                    ) {
                        selectCurrency(currency)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Empty Search Results
    private var emptySearchResults: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text("Валюта не найдена")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Попробуйте изменить запрос")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Current Selection Footer
    private var currentSelectionFooter: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Currency")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Text(appState.userSettings.currency.symbol)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(appState.userSettings.currency.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                Text(formatExampleAmount())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }
    
    // MARK: - Actions
    private func selectCurrency(_ currency: Currency) {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        // If same currency, just dismiss
        if currency == appState.userSettings.currency {
            dismiss()
            return
        }
        
        // Show confirmation for different currency
        selectedCurrency = currency
        showingConfirmation = true
    }
    
    private func changeCurrency(to currency: Currency) {
        isLoading = true
        
        // Update currency synchronously on main thread
        Task { @MainActor in
            appState.updateCurrency(currency)
            
            // Success haptic
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
            
            // Small delay for UX
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            isLoading = false
            dismiss()
        }
    }
    
    private func formatExampleAmount() -> String {
        let exampleAmount = 1234.56
        return appState.userSettings.currency.formatAmount(
            exampleAmount,
            format: appState.userSettings.numberFormat
        )
    }
}

// MARK: - Enhanced Currency Row View
struct CurrencyRowView: View {
    let currency: Currency
    let isSelected: Bool
    let isCurrentlyUsed: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Currency Symbol (professional, no flags)
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.primary.opacity(0.15) : Color.secondary.opacity(0.08))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.primary : Color.secondary.opacity(0.3), lineWidth: 1.5)
                        )
                    
                    Text(currency.symbol)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? Color.primary : .primary)
                }
                
                // Currency Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(currency.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text(currency.code)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if isCurrentlyUsed {
                            Text("• Current")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Spacer()
                
                // Example Amount and Selection
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatExampleAmount())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? Color.primary : .primary)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.primary.opacity(0.08) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.primary.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
    
    private func formatExampleAmount() -> String {
        let exampleAmount = 1234.56
        return "\(currency.symbol)1,234.56"
    }
}

// MARK: - Preview
#Preview("Currency Selection") {
    CurrencySelectionView()
        .environmentObject(AppState.preview)
}

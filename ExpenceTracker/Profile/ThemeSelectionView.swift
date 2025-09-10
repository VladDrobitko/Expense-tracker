//
//  ThemeSelectionView.swift - SIMPLIFIED: Same style as CurrencySelectionView
//  ExpenseTracker
//
//  Created by Developer on 24/06/2025.
//

import SwiftUI

// MARK: - Simplified Theme Selection View (matching Currency style)
struct ThemeSelectionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var currentColorScheme
    
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Theme List (same style as currency)
                themesList
                
                // Current Theme Info
                currentThemeInfo
            }
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
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
        }
    }
    
    // MARK: - Themes List (simplified like currency list)
    private var themesList: some View {
        List {
            ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                SimpleThemeRow(
                    theme: theme,
                    isSelected: appState.userSettings.theme == theme,
                    currentColorScheme: currentColorScheme
                ) {
                    selectTheme(theme)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Current Theme Info (same style as currency footer)
    private var currentThemeInfo: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Theme")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: appState.userSettings.theme.icon)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                        
                        Text(appState.userSettings.theme.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                // Current appearance indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(currentColorScheme == .dark ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    Text(currentColorScheme == .dark ? "Dark" : "Light")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }
    
    // MARK: - Actions
    private func selectTheme(_ theme: AppTheme) {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        // If same theme, just dismiss
        if theme == appState.userSettings.theme {
            dismiss()
            return
        }
        
        isLoading = true
        
        // Update theme synchronously
        Task { @MainActor in
            appState.updateTheme(theme)
            
            // Success haptic
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
            
            // Small delay for UX
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            isLoading = false
            dismiss()
        }
    }
}

// MARK: - Simple Theme Row (matching Currency style)
struct SimpleThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let currentColorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Theme Icon (same style as currency symbol)
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.primary.opacity(0.15) : Color.secondary.opacity(0.08))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.primary : Color.secondary.opacity(0.3), lineWidth: 1.5)
                        )
                    
                    Image(systemName: theme.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? Color.primary : .primary)
                }
                
                // Theme Info (same structure as currency)
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text(themeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if isSelected {
                            Text("• Current")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .fontWeight(.medium)
                        } else if theme == .system {
                            Text("• Now: \(currentColorScheme == .dark ? "Dark" : "Light")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Selection indicator (same as currency)
                VStack(alignment: .trailing, spacing: 4) {
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
    
    private var themeDescription: String {
        switch theme {
        case .system:
            return "Follows system settings"
        case .light:
            return "Light theme"
        case .dark:
            return "Dark theme"
        }
    }
}

// MARK: - Preview
#Preview("Theme Selection") {
    ThemeSelectionView()
        .environmentObject(AppState.preview)
}

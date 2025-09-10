//
//  ProfileView.swift - FIXED: Правильная интеграция экспорта данных
//  ExpenseTracker
//
//  Created by Developer on 24/06/2025.
//

import SwiftUI

// MARK: - Clean Profile View (исправлена интеграция экспорта)
struct ProfileView: View {
    let appState: AppState
    let onClose: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Navigation states
    @State private var showingCurrencySelection = false
    @State private var showingThemeSelection = false
    @State private var showingLanguageSelection = false
    @State private var showingNotificationSettings = false
    @State private var showingCategoryManagement = false
    @State private var showingAbout = false
    
    // ✅ ИСПРАВЛЕНО: Используем полноценный DataExportView вместо простого алерта
    @State private var showingDataExport = false
    @State private var showingClearDataAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Clean header with app info
                appHeaderSection
                
                // Core settings
                coreSettingsSection
                
                // Feature settings
                featureSettingsSection
                
                // Utility settings
                utilitySettingsSection
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(.clear)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.regularMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onClose()
                    }
                    .foregroundColor(.primary)
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(appState.userSettings.theme.colorScheme)
        
        // Navigation sheets
        .sheet(isPresented: $showingCurrencySelection) {
            CurrencySelectionView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingThemeSelection) {
            ThemeSelectionView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingLanguageSelection) {
            LanguageSelectionPlaceholder()
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsPlaceholder(appState: appState)
        }
        .sheet(isPresented: $showingCategoryManagement) {
            CategoryManagementView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingAbout) {
            AboutAppView()
        }
        
        // ✅ ИСПРАВЛЕНО: Используем полноценный DataExportView
        .sheet(isPresented: $showingDataExport) {
            DataExportView(appState: appState)
        }
        
        // Action alerts (только для опасных действий)
        .alert("Clear All Data?", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("All expenses, categories, and settings will be permanently deleted. This action cannot be undone.")
        }
    }
    
    // MARK: - App Header Section (без изменений)
    private var appHeaderSection: some View {
        Section {
            VStack(spacing: 16) {
                // App icon
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.expensePurple, Color.expenseBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    )
                
                VStack(spacing: 4) {
                    Text("ExpenseTracker")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Track expenses & manage data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Quick stats
                HStack(spacing: 24) {
                    VStack(spacing: 2) {
                        Text("\(appState.expenses.count)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.expensePurple)
                        
                        Text("Expenses")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 2) {
                        Text("\(appState.categories.count)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.expenseBlue)
                        
                        Text("Categories")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 2) {
                        Text(appState.formatAmount(appState.thisMonthSpent))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("This Month")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Core Settings Section
    private var coreSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                Button(action: { showingCurrencySelection = true }) {
                    CleanSettingsRow(
                        title: "Currency",
                        subtitle: formattedCurrency,
                        icon: "dollarsign.circle.fill",
                        iconColor: .green
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: { showingThemeSelection = true }) {
                    CleanSettingsRow(
                        title: "Theme",
                        subtitle: formattedTheme,
                        icon: appState.userSettings.theme.icon,
                        iconColor: .purple
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: { showingLanguageSelection = true }) {
                    CleanSettingsRow(
                        title: "Language",
                        subtitle: "\(formattedLanguage) • Coming soon",
                        icon: "globe",
                        iconColor: .blue
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 14)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Feature Settings Section
    private var featureSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Features")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                Button(action: { showingCategoryManagement = true }) {
                    CleanSettingsRow(
                        title: "Categories",
                        subtitle: "Manage expense categories",
                        icon: "folder.fill",
                        iconColor: .indigo
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: { showingNotificationSettings = true }) {
                    CleanSettingsRow(
                        title: "Notifications",
                        subtitle: notificationStatus,
                        icon: "bell.fill",
                        iconColor: appState.userSettings.notificationSettings.isEnabled ? .orange : .gray
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 14)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Utility Settings Section (обновлена)
    private var utilitySettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data & Info")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                // ✅ ИСПРАВЛЕНО: Обновлен субтитл для экспорта
                Button(action: { showingDataExport = true }) {
                    CleanSettingsRow(
                        title: "Export Data",
                        subtitle: exportSubtitle,
                        icon: "square.and.arrow.up",
                        iconColor: .green
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canExport) // ✅ ДОБАВЛЕНО: Отключаем если нет данных
                
                Button(action: { showingClearDataAlert = true }) {
                    CleanSettingsRow(
                        title: "Clear All Data",
                        subtitle: "Reset app to defaults",
                        icon: "trash.fill",
                        iconColor: .red
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: { showingAbout = true }) {
                    CleanSettingsRow(
                        title: "About",
                        subtitle: appInfo,
                        icon: "info.circle.fill",
                        iconColor: .gray
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 14)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Computed Properties
    
    private var formattedCurrency: String {
        "\(appState.userSettings.currency.symbol) \(appState.userSettings.currency.name)"
    }
    
    private var formattedTheme: String {
        appState.userSettings.theme.name
    }
    
    private var formattedLanguage: String {
        appState.userSettings.language.name
    }
    
    private var notificationStatus: String {
        if appState.userSettings.notificationSettings.isEnabled {
            return "Enabled for reminders"
        } else {
            return "Disabled"
        }
    }
    
    private var appInfo: String {
        "Version \(appState.userSettings.appVersion)"
    }
    
    // ✅ НОВЫЕ: Computed properties для экспорта
    private var canExport: Bool {
        !appState.expenses.isEmpty || !appState.categories.isEmpty
    }
    
    private var exportSubtitle: String {
        if !canExport {
            return "No data to export"
        } else if appState.expenses.isEmpty {
            return "Export categories only"
        } else if appState.categories.isEmpty {
            return "Export expenses only"
        } else {
            return "PDF reports & CSV data"
        }
    }
    
    // MARK: - Actions
    
    private func clearAllData() {
        Task {
            print("🗑️ Clearing all data...")
            
            // Haptic feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
            
            // TODO: Implement actual data clearing через AppState
            // await appState.clearAllData()
            
            onClose()
        }
    }
}

// MARK: - Clean Settings Row Component (без изменений)
struct CleanSettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(iconColor)
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
        .opacity(title == "Export Data" && !AppState.shared.expenses.isEmpty ? 1.0 : 1.0) // Можно добавить opacity для disabled состояния
    }
}

// MARK: - Остальные компоненты без изменений
struct LanguageSelectionPlaceholder: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "globe")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary.opacity(0.5))
                    .symbolRenderingMode(.hierarchical)
                
                VStack(spacing: 12) {
                    Text("Language Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Multi-language support is coming soon.\nCurrently available in English only.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                
                VStack(spacing: 8) {
                    Text("Planned languages:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("🇪🇸 Spanish • 🇫🇷 French • 🇩🇪 German • 🇯🇵 Japanese")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .padding(.horizontal, 32)
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct NotificationSettingsPlaceholder: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "bell.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                    .symbolRenderingMode(.hierarchical)
                
                VStack(spacing: 12) {
                    Text("Notification Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Get notified about subscription renewals,\nbudget limits, and spending insights.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                
                VStack(spacing: 8) {
                    Text("Coming soon:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("📅 Subscription reminders\n💰 Budget alerts\n📊 Weekly reports")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                
                Spacer()
            }
            .padding(.horizontal, 32)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct AboutAppView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // App Icon
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.expensePurple, Color.expenseBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    )
                
                VStack(spacing: 16) {
                    Text("ExpenseTracker")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Simple, powerful expense tracking\nfor your everyday life")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                
                VStack(spacing: 8) {
                    Text("Built with ❤️ using SwiftUI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("© 2025 ExpenseTracker")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 32)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview("Clean Profile with Export") {
    ProfileView(appState: AppState.preview) {
        print("Close profile")
    }
}

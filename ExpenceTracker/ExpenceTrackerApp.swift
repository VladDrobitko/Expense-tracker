//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  Created by Developer on 24/06/2025.
//

import SwiftUI
import UserNotifications

@main
struct ExpenseTrackerApp: App {
    
    // MARK: - App State (Singleton)
    @StateObject private var appState = AppState.shared
    
    // MARK: - Scene Delegate для lifecycle events
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState) // Инжектируем AppState во всё приложение
                .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
                .preferredColorScheme(appState.userSettings.theme.colorScheme) // Реактивная тема
                .onAppear {
                    // Загружаем данные при запуске
                    Task {
                        await appState.loadInitialData()
                    }
                }
                .onChange(of: appState.userSettings.theme) { newTheme in
                    // Реактивно обновляем тему при её изменении
                    print("🎨 App: Theme changed to \(newTheme.rawValue)")
                }
                .alert("Ошибка", isPresented: .constant(appState.errorMessage != nil)) {
                    Button("OK") {
                        appState.clearError()
                    }
                } message: {
                    Text(appState.errorMessage ?? "")
                }
        }
    }
}

// MARK: - Content View (главный экран)
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isLoading {
                LoadingView()
            } else {
                ExpenseHomeView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isLoading)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Logo с анимацией
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.expensePurple.opacity(0.3), Color.expenseBlue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.expensePurple, Color.expenseBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    )
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            }
            
            VStack(spacing: 12) {
                Text("ExpenseTracker")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Загрузка данных...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(Color.expensePurple)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.expensePurple.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - App Delegate для системных событий
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        print("🚀 ExpenseTracker: App launched")
        
        // Настройка уведомлений
        setupNotifications()
        
        // Настройка внешнего вида
        setupAppearance()
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("📱 ExpenseTracker: Entered background")
        
        // Сохраняем данные при уходе в фон
        CoreDataStack.shared.save()
        
        // Скрываем суммы если настроено
        if AppState.shared.userSettings.privacySettings.hideAmountsInBackground {
            hideAmountsInSnapshot()
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("📱 ExpenseTracker: Will enter foreground")
        
        // Обновляем данные при возврате
        Task { @MainActor in
            await AppState.shared.refreshData()
        }
    }
    
    // MARK: - Private Setup Methods
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        
        // Проверяем текущий статус разрешений
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("📱 Notification status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    private func setupAppearance() {
        // Настройка глобального внешнего вида
        
        // Navigation Bar
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.systemBackground
        navBarAppearance.shadowColor = UIColor.clear
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Tab Bar (если будет в будущем)
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        print("🎨 ExpenseTracker: Appearance configured")
    }
    
    private func hideAmountsInSnapshot() {
        // В реальном приложении здесь был бы код для скрытия sensitive data
        // в screenshot для App Switcher
        print("🔒 ExpenseTracker: Hiding amounts in snapshot")
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Обработка уведомлений когда приложение активно
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        
        print("📱 Received notification while app active: \(notification.request.identifier)")
        
        // Показываем уведомление даже когда приложение активно
        completionHandler([.banner, .sound])
    }
    
    // Обработка нажатий на уведомления
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        
        let identifier = response.notification.request.identifier
        print("📱 User tapped notification: \(identifier)")
        
        // Обрабатываем различные типы уведомлений
        Task { @MainActor in
            await handleNotificationTap(identifier: identifier)
        }
        
        completionHandler()
    }
    
    @MainActor
    private func handleNotificationTap(identifier: String) async {
        switch identifier {
        case "daily_reminder":
            // Открываем экран добавления траты
            print("📱 Opening add expense from notification")
            
        case "budget_warning_75", "budget_exceeded":
            // Открываем экран бюджета
            print("📱 Opening budget settings from notification")
            
        case "weekly_report":
            // Открываем статистику
            print("📱 Opening stats from notification")
            
        default:
            // Просто обновляем данные
            await AppState.shared.refreshData()
        }
    }
}

// MARK: - Preview Support
#Preview("Loading") {
    LoadingView()
}

#Preview("Content") {
    ContentView()
        .environmentObject(AppState.preview)
}

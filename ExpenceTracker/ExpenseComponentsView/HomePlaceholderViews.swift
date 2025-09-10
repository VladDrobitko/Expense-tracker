//
//  HomePlaceholderViews.swift - Заглушки для модальных окон (обновлено)
//  ExpenseTracker
//
//  Created by Developer on 24/06/2025.
//

import SwiftUI

// MARK: - Quick Actions View
struct QuickActionsView: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                        .symbolRenderingMode(.hierarchical)
                    
                    Text("Быстрые действия")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureItem(title: "Шаблоны трат", subtitle: "Сохраненные часто используемые траты")
                    FeatureItem(title: "Управление подписками", subtitle: "Отслеживание регулярных платежей")
                    FeatureItem(title: "Предстоящие платежи", subtitle: "Напоминания о будущих тратах")
                    FeatureItem(title: "Быстрые категории", subtitle: "Часто используемые категории")
                }
                
                Spacer()
                
                Text("Скоро в обновлениях...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Быстрые действия")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(Color.expensePurple)
                }
            }
        }
    }
}

// MARK: - Statistics View
struct StatisticsView: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                        .symbolRenderingMode(.hierarchical)
                    
                    Text("Статистика и аналитика")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureItem(title: "Графики по категориям", subtitle: "Визуализация расходов по типам")
                    FeatureItem(title: "Тренды по месяцам", subtitle: "Динамика трат за период")
                    FeatureItem(title: "Топ расходов", subtitle: "Самые крупные траты")
                    FeatureItem(title: "Фильтры и экспорт", subtitle: "Детальный анализ данных")
                }
                
                Spacer()
                
                Text("Скоро в обновлениях...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Статистика")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(Color.expensePurple)
                }
            }
        }
    }
}

// ✅ УБРАЛИ SearchView - теперь есть полноценный в HomeViewComponents.swift

// MARK: - Feature Item Component
struct FeatureItem: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.expensePurple.opacity(0.1))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

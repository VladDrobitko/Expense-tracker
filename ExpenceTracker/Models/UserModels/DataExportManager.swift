//
//  DataExportManager.swift - ПОЛНОСТЬЮ ИСПРАВЛЕНО: все ошибки типов
//  ExpenseTracker
//
//  Created by Developer on 24/06/2025.
//

import SwiftUI
import Foundation
import UIKit

// MARK: - Data Export Manager (ПОЛНОСТЬЮ ИСПРАВЛЕНО)
@MainActor
class DataExportManager: ObservableObject {
    
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var errorMessage: String?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    private let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        return formatter
    }()
    
    // MARK: - Export with Format Selection
    func exportData(
        option: ExportOption,
        expenses: [Expense],
        categories: [Category],
        currency: Currency,
        userSettings: AppSettings
    ) async -> URL? {
        
        isExporting = true
        exportProgress = 0.0
        errorMessage = nil
        
        do {
            let url: URL?
            
            switch option {
            case .expensesPDF:
                url = try await exportExpensesPDFSimple(expenses: expenses, categories: categories, currency: currency, userSettings: userSettings)
            case .expensesCSV:
                url = await exportExpensesCSV(expenses: expenses, categories: categories, currency: currency)
            case .categoriesCSV:
                url = await exportCategoriesCSV(categories: categories)
            case .fullPDF:
                url = try await exportFullPDFSimple(expenses: expenses, categories: categories, currency: currency, userSettings: userSettings)
            case .fullCSV:
                url = await exportFullCSV(expenses: expenses, categories: categories, currency: currency)
            }
            
            exportProgress = 1.0
            isExporting = false
            return url
            
        } catch {
            isExporting = false
            errorMessage = "Export failed: \(error.localizedDescription)"
            print("❌ Export error: \(error)")
            return nil
        }
    }
    
    // MARK: - PDF Export Methods
    private func exportExpensesPDFSimple(expenses: [Expense], categories: [Category], currency: Currency, userSettings: AppSettings) async throws -> URL {
        exportProgress = 0.2
        
        let fileName = "ExpenseTracker_Report_\(fileNameFormatter.string(from: Date())).pdf"
        let url = try await createSimplePDF(
            expenses: expenses,
            categories: categories,
            currency: currency,
            userSettings: userSettings,
            fileName: fileName,
            includeCategories: false
        )
        
        exportProgress = 0.9
        return url
    }
    
    private func exportFullPDFSimple(expenses: [Expense], categories: [Category], currency: Currency, userSettings: AppSettings) async throws -> URL {
        exportProgress = 0.2
        
        let fileName = "ExpenseTracker_FullReport_\(fileNameFormatter.string(from: Date())).pdf"
        let url = try await createSimplePDF(
            expenses: expenses,
            categories: categories,
            currency: currency,
            userSettings: userSettings,
            fileName: fileName,
            includeCategories: true
        )
        
        exportProgress = 0.9
        return url
    }
    
    // MARK: - Создание PDF через Core Graphics
    private func createSimplePDF(
        expenses: [Expense],
        categories: [Category],
        currency: Currency,
        userSettings: AppSettings,
        fileName: String,
        includeCategories: Bool
    ) async throws -> URL {
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileURL = documentsPath.appendingPathComponent(fileName)
                    
                    // Создаем PDF context
                    let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size
                    
                    UIGraphicsBeginPDFContextToFile(fileURL.path, pageRect, nil)
                    
                    guard UIGraphicsGetCurrentContext() != nil else {
                        throw ExportError.pdfCreationFailed("Could not create PDF context")
                    }
                    
                    // Начинаем первую страницу
                    UIGraphicsBeginPDFPage()
                    
                    let stats = self.generateExportStats(expenses: expenses, categories: categories)
                    let sortedExpenses = expenses.sorted { $0.safeDate > $1.safeDate }
                    
                    // Рисуем содержимое PDF
                    self.drawPDFContent(
                        pageRect: pageRect,
                        stats: stats,
                        expenses: sortedExpenses,
                        categories: includeCategories ? categories : [],
                        currency: currency,
                        userSettings: userSettings
                    )
                    
                    // Завершаем PDF
                    UIGraphicsEndPDFContext()
                    
                    print("📄 Simple PDF exported to: \(fileURL.path)")
                    
                    DispatchQueue.main.async {
                        continuation.resume(returning: fileURL)
                    }
                    
                } catch {
                    print("❌ Simple PDF creation failed: \(error)")
                    DispatchQueue.main.async {
                        continuation.resume(throwing: ExportError.pdfCreationFailed(error.localizedDescription))
                    }
                }
            }
        }
    }
    
    // MARK: - Рисование содержимого PDF (ИСПРАВЛЕНО)
    private func drawPDFContent(
        pageRect: CGRect,
        stats: ExportStats,
        expenses: [Expense],
        categories: [Category],
        currency: Currency,
        userSettings: AppSettings
    ) {
        let margin: CGFloat = 50
        var yPosition: CGFloat = margin
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.systemPurple
        ]
        
        let title = "💰 ExpenseTracker Report"
        let titleSize = title.size(withAttributes: titleAttributes)
        title.draw(
            at: CGPoint(x: (pageRect.width - titleSize.width) / 2, y: yPosition),
            withAttributes: titleAttributes
        )
        yPosition += (titleSize.height + 15)
        
        // Subtitle
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.systemGray
        ]
        
        let subtitle = "Generated on \(dateFormatter.string(from: Date()))"
        let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
        subtitle.draw(
            at: CGPoint(x: (pageRect.width - subtitleSize.width) / 2, y: yPosition),
            withAttributes: subtitleAttributes
        )
        yPosition += (subtitleSize.height + 25)
        
        // Stats box
        drawStatsBox(stats: stats, currency: currency, userSettings: userSettings, pageRect: pageRect, yPosition: yPosition)
        yPosition += 80
        
        // Expenses header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.label
        ]
        
        let expensesHeader = "Recent Expenses (\(min(expenses.count, 15)) of \(expenses.count))"
        expensesHeader.draw(
            at: CGPoint(x: margin, y: yPosition),
            withAttributes: headerAttributes
        )
        yPosition += 25
        
        // Рисуем линию под заголовком
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(UIColor.systemGray4.cgColor)
            context.setLineWidth(1)
            context.move(to: CGPoint(x: margin, y: yPosition))
            context.addLine(to: CGPoint(x: pageRect.width - margin, y: yPosition))
            context.strokePath()
        }
        yPosition += 15
        
        // Проверяем что у нас есть траты
        if expenses.isEmpty {
            let noExpensesAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 14),
                .foregroundColor: UIColor.systemGray2
            ]
            
            let noExpensesText = "No expenses found."
            noExpensesText.draw(
                at: CGPoint(x: margin, y: yPosition),
                withAttributes: noExpensesAttributes
            )
            yPosition += 30
        } else {
            // Рисуем максимум 15 трат
            let maxExpenses = min(expenses.count, 15)
            for expense in expenses.prefix(maxExpenses) {
                // Проверяем место на странице
                if yPosition > pageRect.height - margin - 60 {
                    UIGraphicsBeginPDFPage()
                    yPosition = margin
                    
                    // Повторяем заголовок на новой странице
                    let continueHeader = "Expenses (continued...)"
                    continueHeader.draw(
                        at: CGPoint(x: margin, y: yPosition),
                        withAttributes: headerAttributes
                    )
                    yPosition += 35
                }
                
                drawExpenseRow(
                    expense: expense,
                    currency: currency,
                    userSettings: userSettings,
                    pageRect: pageRect,
                    yPosition: yPosition,
                    margin: margin
                )
                yPosition += 35
            }
            
            // Показываем если есть еще траты
            if expenses.count > maxExpenses {
                yPosition += 10
                let moreExpensesAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: 12),
                    .foregroundColor: UIColor.systemGray
                ]
                
                let moreText = "... and \(expenses.count - maxExpenses) more expenses"
                moreText.draw(
                    at: CGPoint(x: margin, y: yPosition),
                    withAttributes: moreExpensesAttributes
                )
                yPosition += 25
            }
        }
        
        // Categories if included
        if !categories.isEmpty {
            yPosition += 30
            
            // Проверяем место для категорий
            if yPosition > pageRect.height - margin - 200 {
                UIGraphicsBeginPDFPage()
                yPosition = margin
            }
            
            let categoriesHeader = "Categories (\(categories.count) items)"
            categoriesHeader.draw(
                at: CGPoint(x: margin, y: yPosition),
                withAttributes: headerAttributes
            )
            yPosition += 25
            
            // Линия под заголовком категорий
            if let context = UIGraphicsGetCurrentContext() {
                context.setStrokeColor(UIColor.systemGray4.cgColor)
                context.setLineWidth(1)
                context.move(to: CGPoint(x: margin, y: yPosition))
                context.addLine(to: CGPoint(x: pageRect.width - margin, y: yPosition))
                context.strokePath()
            }
            yPosition += 15
            
            for category in categories.sorted(by: { $0.order < $1.order }).prefix(10) {
                if yPosition > pageRect.height - margin - 40 {
                    UIGraphicsBeginPDFPage()
                    yPosition = margin
                }
                
                drawCategoryRow(
                    category: category,
                    pageRect: pageRect,
                    yPosition: yPosition,
                    margin: margin
                )
                yPosition += 30
            }
        }
        
        // Footer на последней странице
        drawFooter(pageRect: pageRect, stats: stats)
    }
    
    // MARK: - Красивая статистика в рамке (ИСПРАВЛЕНО)
    private func drawStatsBox(stats: ExportStats, currency: Currency, userSettings: AppSettings, pageRect: CGRect, yPosition: CGFloat) {
        let margin: CGFloat = 50
        let boxHeight: CGFloat = 60
        let boxRect = CGRect(x: margin, y: yPosition, width: pageRect.width - margin * 2, height: boxHeight)
        
        // Рисуем рамку
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(UIColor.systemGray6.cgColor)
            context.fill(boxRect)
            
            context.setStrokeColor(UIColor.systemGray4.cgColor)
            context.setLineWidth(1)
            context.stroke(boxRect)
        }
        
        // Три колонки статистики
        let columnWidth = (boxRect.width - 40) / 3
        let startX = boxRect.minX + 20
        
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.systemPurple
        ]
        
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.systemGray
        ]
        
        // Expenses count
        let expensesValue = "\(stats.expenseCount)"
        let expensesLabel = "EXPENSES"
        let expensesValueSize = expensesValue.size(withAttributes: valueAttributes)
        let expensesLabelSize = expensesLabel.size(withAttributes: labelAttributes)
        
        expensesValue.draw(
            at: CGPoint(x: startX + columnWidth/2 - expensesValueSize.width/2, y: yPosition + 15),
            withAttributes: valueAttributes
        )
        expensesLabel.draw(
            at: CGPoint(x: startX + columnWidth/2 - expensesLabelSize.width/2, y: yPosition + 35),
            withAttributes: labelAttributes
        )
        
        // Total amount
        let totalValue = currency.formatAmount(stats.totalAmount, format: userSettings.numberFormat)
        let totalLabel = "TOTAL AMOUNT"
        let totalValueSize = totalValue.size(withAttributes: valueAttributes)
        let totalLabelSize = totalLabel.size(withAttributes: labelAttributes)
        let totalX = startX + columnWidth
        
        totalValue.draw(
            at: CGPoint(x: totalX + columnWidth/2 - totalValueSize.width/2, y: yPosition + 15),
            withAttributes: valueAttributes
        )
        totalLabel.draw(
            at: CGPoint(x: totalX + columnWidth/2 - totalLabelSize.width/2, y: yPosition + 35),
            withAttributes: labelAttributes
        )
        
        // Categories used
        let categoriesValue = "\(stats.categoriesUsed)"
        let categoriesLabel = "CATEGORIES"
        let categoriesValueSize = categoriesValue.size(withAttributes: valueAttributes)
        let categoriesLabelSize = categoriesLabel.size(withAttributes: labelAttributes)
        let categoriesX = startX + columnWidth * 2
        
        categoriesValue.draw(
            at: CGPoint(x: categoriesX + columnWidth/2 - categoriesValueSize.width/2, y: yPosition + 15),
            withAttributes: valueAttributes
        )
        categoriesLabel.draw(
            at: CGPoint(x: categoriesX + columnWidth/2 - categoriesLabelSize.width/2, y: yPosition + 35),
            withAttributes: labelAttributes
        )
    }
    
    // MARK: - Улучшенное отображение трат (ИСПРАВЛЕНО)
    private func drawExpenseRow(expense: Expense, currency: Currency, userSettings: AppSettings, pageRect: CGRect, yPosition: CGFloat, margin: CGFloat) {
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13),
            .foregroundColor: UIColor.label
        ]
        
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.systemGray
        ]
        
        let amountAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13),
            .foregroundColor: UIColor.systemPurple
        ]
        
        // ✅ ИСПРАВЛЕНО: Рисуем левый маркер (цветная полоска)
        if let context = UIGraphicsGetCurrentContext() {
            // ✅ ИСПРАВЛЕНО: Правильное преобразование Color в UIColor
            let categoryUIColor: UIColor
            if let category = expense.category {
                categoryUIColor = UIColor(category.color)
            } else {
                categoryUIColor = UIColor.systemGray
            }
            
            context.setFillColor(categoryUIColor.cgColor)
            let markerRect = CGRect(x: margin, y: yPosition, width: 3, height: 25)
            context.fill(markerRect)
        }
        
        let contentX = margin + 15
        
        // Name (в одну строку с truncation)
        let maxNameWidth = pageRect.width - margin - 150
        let nameTruncated = truncateText(expense.safeName, maxWidth: maxNameWidth, attributes: nameAttributes)
        nameTruncated.draw(
            at: CGPoint(x: contentX, y: yPosition),
            withAttributes: nameAttributes
        )
        
        // Details (категория и дата)
        let categoryName = expense.category?.safeName ?? "Uncategorized"
        let formattedDate = DateFormatter.localizedString(from: expense.safeDate, dateStyle: .medium, timeStyle: .short)
        let details = "\(categoryName) • \(formattedDate)"
        details.draw(
            at: CGPoint(x: contentX, y: yPosition + 17),
            withAttributes: detailAttributes
        )
        
        // Amount (выровнен по правому краю)
        let amount = currency.formatAmount(expense.amount, format: userSettings.numberFormat)
        let amountSize = amount.size(withAttributes: amountAttributes)
        amount.draw(
            at: CGPoint(x: pageRect.width - margin - amountSize.width, y: yPosition + 5),
            withAttributes: amountAttributes
        )
        
        // Рисуем тонкую линию разделитель
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(UIColor.systemGray5.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: contentX, y: yPosition + 32))
            context.addLine(to: CGPoint(x: pageRect.width - margin, y: yPosition + 32))
            context.strokePath()
        }
    }
    
    // MARK: - Обрезка текста если слишком длинный
    private func truncateText(_ text: String, maxWidth: CGFloat, attributes: [NSAttributedString.Key: Any]) -> String {
        let textSize = text.size(withAttributes: attributes)
        
        if textSize.width <= maxWidth {
            return text
        }
        
        // Обрезаем текст и добавляем "..."
        let ellipsis = "..."
        let ellipsisSize = ellipsis.size(withAttributes: attributes)
        let availableWidth = maxWidth - ellipsisSize.width
        
        var truncated = ""
        for char in text {
            let testString = truncated + String(char)
            let testSize = testString.size(withAttributes: attributes)
            
            if testSize.width > availableWidth {
                break
            }
            truncated += String(char)
        }
        
        return truncated + ellipsis
    }
    
    // MARK: - Улучшенное отображение категорий (ИСПРАВЛЕНО)
    private func drawCategoryRow(category: Category, pageRect: CGRect, yPosition: CGFloat, margin: CGFloat) {
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.label
        ]
        
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.systemGray
        ]
        
        // ✅ ИСПРАВЛЕНО: Рисуем цветной квадратик
        if let context = UIGraphicsGetCurrentContext() {
            let categoryUIColor = UIColor(category.color)
            context.setFillColor(categoryUIColor.cgColor)
            let colorRect = CGRect(x: margin, y: yPosition + 2, width: 12, height: 12)
            context.fill(colorRect)
            
            // Рамка вокруг квадратика
            context.setStrokeColor(UIColor.systemGray4.cgColor)
            context.setLineWidth(0.5)
            context.stroke(colorRect)
        }
        
        let contentX = margin + 20
        
        // Icon and name
        let iconAndName = "\(category.safeIcon) \(category.safeName)"
        iconAndName.draw(
            at: CGPoint(x: contentX, y: yPosition),
            withAttributes: nameAttributes
        )
        
        // Details
        let details = "Order: \(category.order) • \(category.isActive ? "Active" : "Inactive")"
        details.draw(
            at: CGPoint(x: contentX, y: yPosition + 15),
            withAttributes: detailAttributes
        )
        
        // Тонкая линия разделитель
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(UIColor.systemGray5.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: contentX, y: yPosition + 27))
            context.addLine(to: CGPoint(x: pageRect.width - margin, y: yPosition + 27))
            context.strokePath()
        }
    }
    
    // MARK: - Footer с дополнительной информацией
    private func drawFooter(pageRect: CGRect, stats: ExportStats) {
        let footerY = pageRect.height - 40
        let margin: CGFloat = 50
        
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.systemGray
        ]
        
        // Левая часть - информация о периоде
        let periodText = "Period: \(stats.formattedDateRange)"
        periodText.draw(
            at: CGPoint(x: margin, y: footerY),
            withAttributes: footerAttributes
        )
        
        // Правая часть - информация о приложении
        let appText = "Generated by ExpenseTracker iOS"
        let appTextSize = appText.size(withAttributes: footerAttributes)
        appText.draw(
            at: CGPoint(x: pageRect.width - margin - appTextSize.width, y: footerY),
            withAttributes: footerAttributes
        )
        
        // Линия сверху footer'а
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(UIColor.systemGray5.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: margin, y: footerY - 10))
            context.addLine(to: CGPoint(x: pageRect.width - margin, y: footerY - 10))
            context.strokePath()
        }
    }
    
    // MARK: - CSV Export Methods (БЕЗ ИЗМЕНЕНИЙ)
    private func exportExpensesCSV(expenses: [Expense], categories: [Category], currency: Currency) async -> URL? {
        exportProgress = 0.3
        let csvContent = generateExpensesCSV(expenses: expenses, categories: categories, currency: currency)
        exportProgress = 0.7
        
        do {
            let fileName = "ExpenseTracker_Expenses_\(fileNameFormatter.string(from: Date())).csv"
            let url = try await saveCSVToDocuments(csvContent: csvContent, fileName: fileName)
            return url
        } catch {
            errorMessage = "CSV export failed: \(error.localizedDescription)"
            return nil
        }
    }
    
    private func exportCategoriesCSV(categories: [Category]) async -> URL? {
        exportProgress = 0.3
        let csvContent = generateCategoriesCSV(categories: categories)
        exportProgress = 0.7
        
        do {
            let fileName = "ExpenseTracker_Categories_\(fileNameFormatter.string(from: Date())).csv"
            let url = try await saveCSVToDocuments(csvContent: csvContent, fileName: fileName)
            return url
        } catch {
            errorMessage = "CSV export failed: \(error.localizedDescription)"
            return nil
        }
    }
    
    private func exportFullCSV(expenses: [Expense], categories: [Category], currency: Currency) async -> URL? {
        exportProgress = 0.2
        let expensesCSV = generateExpensesCSV(expenses: expenses, categories: categories, currency: currency)
        exportProgress = 0.4
        let categoriesCSV = generateCategoriesCSV(categories: categories)
        exportProgress = 0.6
        let combinedContent = createCombinedCSV(expensesCSV: expensesCSV, categoriesCSV: categoriesCSV)
        exportProgress = 0.8
        
        do {
            let fileName = "ExpenseTracker_FullData_\(fileNameFormatter.string(from: Date())).csv"
            let url = try await saveCSVToDocuments(csvContent: combinedContent, fileName: fileName)
            return url
        } catch {
            errorMessage = "CSV export failed: \(error.localizedDescription)"
            return nil
        }
    }
    
    private func saveCSVToDocuments(csvContent: String, fileName: String) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileURL = documentsPath.appendingPathComponent(fileName)
                    
                    try FileManager.default.createDirectory(at: documentsPath, withIntermediateDirectories: true, attributes: nil)
                    
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        try FileManager.default.removeItem(at: fileURL)
                    }
                    
                    let bomData = Data([0xEF, 0xBB, 0xBF])
                    let csvData = csvContent.data(using: .utf8) ?? Data()
                    let finalData = bomData + csvData
                    
                    try finalData.write(to: fileURL)
                    
                    print("📤 CSV exported to: \(fileURL.path)")
                    print("📤 CSV size: \(finalData.count) bytes")
                    
                    continuation.resume(returning: fileURL)
                    
                } catch {
                    print("❌ CSV export error: \(error)")
                    continuation.resume(throwing: ExportError.fileSaveError(error.localizedDescription))
                }
            }
        }
    }
    
    // MARK: - CSV Generation
    private func generateExpensesCSV(expenses: [Expense], categories: [Category], currency: Currency) -> String {
        var csvContent = ""
        csvContent += "Date,Amount,Currency,Name,Category,Notes,Created At\n"
        
        let sortedExpenses = expenses.sorted { $0.safeDate > $1.safeDate }
        
        for expense in sortedExpenses {
            let date = dateFormatter.string(from: expense.safeDate)
            let amount = String(format: "%.2f", expense.amount)
            let currencyCode = currency.code
            let name = escapeCSVField(expense.safeName)
            let categoryName = escapeCSVField(expense.category?.safeName ?? "Uncategorized")
            let notes = escapeCSVField(expense.notes ?? "")
            let createdAt = dateFormatter.string(from: expense.createdAt ?? expense.safeDate)
            
            csvContent += "\(date),\(amount),\(currencyCode),\(name),\(categoryName),\(notes),\(createdAt)\n"
        }
        
        return csvContent
    }
    
    private func generateCategoriesCSV(categories: [Category]) -> String {
        var csvContent = ""
        csvContent += "Name,Icon,Color,Order,Active,Created At\n"
        
        let sortedCategories = categories.sorted { $0.order < $1.order }
        
        for category in sortedCategories {
            let name = escapeCSVField(category.safeName)
            let icon = escapeCSVField(category.safeIcon)
            let color = escapeCSVField(category.colorHex ?? "000000")
            let order = String(category.order)
            let active = category.isActive ? "Yes" : "No"
            let createdAt = dateFormatter.string(from: category.createdAt ?? Date())
            
            csvContent += "\(name),\(icon),\(color),\(order),\(active),\(createdAt)\n"
        }
        
        return csvContent
    }
    
    private func createCombinedCSV(expensesCSV: String, categoriesCSV: String) -> String {
        var combinedContent = ""
        combinedContent += "# ExpenseTracker Full Data Export\n"
        combinedContent += "# Export Date: \(dateFormatter.string(from: Date()))\n"
        combinedContent += "# Generated by ExpenseTracker iOS App\n"
        combinedContent += "\n"
        combinedContent += "# EXPENSES DATA\n"
        combinedContent += expensesCSV
        combinedContent += "\n"
        combinedContent += "# CATEGORIES DATA\n"
        combinedContent += categoriesCSV
        
        return combinedContent
    }
    
    private func escapeCSVField(_ field: String) -> String {
        let trimmed = field.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.contains(",") || trimmed.contains("\"") || trimmed.contains("\n") {
            let escaped = trimmed.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        
        return trimmed
    }
    
    // MARK: - Utility Methods
    func clearError() {
        errorMessage = nil
    }
    
    func reset() {
        isExporting = false
        exportProgress = 0.0
        errorMessage = nil
    }
    
    func generateExportStats(expenses: [Expense], categories: [Category]) -> ExportStats {
        let totalAmount = expenses.reduce(0) { $0 + $1.amount }
        let dateRange = getDateRange(from: expenses)
        let categoriesUsed = Set(expenses.compactMap { $0.category?.identifier }).count
        
        return ExportStats(
            expenseCount: expenses.count,
            categoryCount: categories.count,
            totalAmount: totalAmount,
            dateRange: dateRange,
            categoriesUsed: categoriesUsed,
            exportDate: Date()
        )
    }
    
    private func getDateRange(from expenses: [Expense]) -> (start: Date?, end: Date?) {
        guard !expenses.isEmpty else { return (nil, nil) }
        
        let dates = expenses.map { $0.safeDate }
        let startDate = dates.min()
        let endDate = dates.max()
        
        return (startDate, endDate)
    }
}

// MARK: - Export Error Types
enum ExportError: LocalizedError {
    case webViewError(String)
    case pdfCreationFailed(String)
    case fileSaveError(String)
    
    var errorDescription: String? {
        switch self {
        case .webViewError(let message):
            return "WebView error: \(message)"
        case .pdfCreationFailed(let message):
            return "PDF creation failed: \(message)"
        case .fileSaveError(let message):
            return "File save error: \(message)"
        }
    }
}

// MARK: - Export Stats Model
struct ExportStats {
    let expenseCount: Int
    let categoryCount: Int
    let totalAmount: Double
    let dateRange: (start: Date?, end: Date?)
    let categoriesUsed: Int
    let exportDate: Date
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        guard let start = dateRange.start, let end = dateRange.end else {
            return "No data"
        }
        
        if Calendar.current.isDate(start, inSameDayAs: end) {
            return formatter.string(from: start)
        } else {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }
}

// MARK: - Preview Support
extension DataExportManager {
    static let preview: DataExportManager = {
        DataExportManager()
    }()
}

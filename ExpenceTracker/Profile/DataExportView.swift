//
//  DataExportView.swift - Complete Export UI with Share Sheet (FIXED)
//  ExpenseTracker
//
//  Created by Developer on 24/06/2025.
//

import SwiftUI

// MARK: - Data Export View (ИСПРАВЛЕНО)
struct DataExportView: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var exportManager = DataExportManager()
    @State private var selectedOption: ExportOption = .expensesPDF // Default to PDF
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var showingSuccessAlert = false
    @State private var showingDocumentPicker = false
    
    private var exportStats: ExportStats {
        exportManager.generateExportStats(
            expenses: appState.expenses,
            categories: appState.categories
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if exportManager.isExporting {
                    exportingView
                } else {
                    exportOptionsView
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(exportManager.isExporting)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        performExport()
                    }
                    .fontWeight(.semibold)
                    .disabled(exportManager.isExporting || !canExport)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Export Complete", isPresented: $showingSuccessAlert) {
            Button("Share File") {
                showingShareSheet = true
            }
            Button("Save to Files") {
                if let url = exportedFileURL {
                    showingDocumentPicker = true
                }
            }
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("Your data has been exported successfully. You can share the file or save it to Files app.")
        }
        .sheet(isPresented: $showingDocumentPicker) {
            if let url = exportedFileURL {
                DocumentExportSheet(fileURL: url)
            }
        }
        .alert("Export Error", isPresented: .constant(exportManager.errorMessage != nil)) {
            Button("OK") {
                exportManager.clearError()
            }
        } message: {
            if let error = exportManager.errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Export Options View
    private var exportOptionsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Export Stats Header
                exportStatsHeader
                
                // Export Options
                exportOptionsSection
                
                // Selected Option Details
                selectedOptionDetails
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Export Stats Header
    private var exportStatsHeader: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(.regularMaterial)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.3), lineWidth: 2)
                    )
                
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 8) {
                Text("Export Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Create beautiful PDF reports or CSV files for analysis")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Quick Stats
            HStack(spacing: 24) {
                StatItem(
                    value: "\(exportStats.expenseCount)",
                    label: "Expenses",
                    color: .primary
                )
                
                StatItem(
                    value: "\(exportStats.categoryCount)",
                    label: "Categories",
                    color: .primary
                )
                
                StatItem(
                    value: appState.formatAmount(exportStats.totalAmount),
                    label: "Total",
                    color: .primary
                )
            }
            
            if exportStats.expenseCount > 0 {
                Text("Date Range: \(exportStats.formattedDateRange)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Export Options Section
    private var exportOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Options")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ForEach(ExportOption.allCases, id: \.rawValue) { option in
                    ExportOptionRow(
                        option: option,
                        isSelected: selectedOption == option,
                        isEnabled: isOptionEnabled(option)
                    ) {
                        selectedOption = option
                        
                        // Haptic feedback
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                }
            }
        }
    }
    
    // MARK: - Selected Option Details
    private var selectedOptionDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Details")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                DetailRow(
                    icon: "doc.text",
                    title: "File Format",
                    value: selectedOption.isPDF ? "PDF (Portable Document)" : "CSV (Comma Separated Values)"
                )
                
                DetailRow(
                    icon: "calendar",
                    title: "Export Date",
                    value: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
                )
                
                DetailRow(
                    icon: "folder",
                    title: "Save Location",
                    value: "Files app → On My iPhone → ExpenseTracker"
                )
                
                if selectedOption == .expensesPDF || selectedOption == .expensesCSV || selectedOption == .fullPDF || selectedOption == .fullCSV {
                    DetailRow(
                        icon: "list.bullet",
                        title: "Expense Fields",
                        value: "Date, Amount, Currency, Name, Category, Notes"
                    )
                }
                
                if selectedOption == .categoriesCSV || selectedOption == .fullPDF || selectedOption == .fullCSV {
                    DetailRow(
                        icon: "tag",
                        title: "Category Fields",
                        value: "Name, Icon, Color, Order, Status"
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Exporting View
    private var exportingView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.2), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: exportManager.exportProgress)
                        .stroke(Color.primary, lineWidth: 8)
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: exportManager.exportProgress)
                    
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                VStack(spacing: 8) {
                    Text("Exporting Data...")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("\(Int(exportManager.exportProgress * 100))% Complete")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(exportProgressText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Computed Properties
    
    private var canExport: Bool {
        selectedOption.isAvailable(expenses: appState.expenses, categories: appState.categories)
    }
    
    private var exportProgressText: String {
        let progress = exportManager.exportProgress
        
        if selectedOption.isPDF {
            if progress < 0.3 {
                return "Generating HTML content..."
            } else if progress < 0.7 {
                return "Creating PDF document..."
            } else {
                return "Finalizing export..."
            }
        } else {
            if progress < 0.4 {
                return "Generating CSV content..."
            } else if progress < 0.8 {
                return "Creating file..."
            } else {
                return "Finalizing export..."
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func isOptionEnabled(_ option: ExportOption) -> Bool {
        return option.isAvailable(expenses: appState.expenses, categories: appState.categories)
    }
    
    private func performExport() {
        // Проверяем что опция доступна
        guard selectedOption.isAvailable(expenses: appState.expenses, categories: appState.categories) else {
            return
        }
        
        Task {
            let url = await exportManager.exportData(
                option: selectedOption,
                expenses: appState.expenses,
                categories: appState.categories,
                currency: appState.userSettings.currency,
                userSettings: appState.userSettings
            )
            
            if let url = url {
                exportedFileURL = url
                showingSuccessAlert = true
                
                // Haptic feedback
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.success)
            }
        }
    }
}

// MARK: - Export Option Row
struct ExportOptionRow: View {
    let option: ExportOption
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.primary.opacity(0.15) : Color.secondary.opacity(0.08))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.primary : Color.secondary.opacity(0.3), lineWidth: 1.5)
                        )
                    
                    Image(systemName: option.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? Color.primary : (isEnabled ? .primary : .secondary))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(option.title)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(isEnabled ? .primary : .secondary)
                        
                        if let tag = option.recommendedTag {
                            Text(tag)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.expensePurple)
                                )
                        }
                        
                        Spacer()
                    }
                    
                    Text(option.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.primary.opacity(0.05) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.primary.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Share Sheet (ИСПРАВЛЕНО)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // ✅ ИСПРАВЛЕНО: Правильная обработка URL файлов
        let processedItems = items.map { item -> Any in
            if let url = item as? URL {
                // ✅ Для файлов возвращаем URL как есть, но убеждаемся что файл доступен
                do {
                    let _ = try url.checkResourceIsReachable()
                    print("📤 Share: File is reachable at \(url.path)")
                    return url
                } catch {
                    print("❌ Share: File not reachable: \(error)")
                    // Возвращаем путь как строку если файл недоступен
                    return url.lastPathComponent
                }
            }
            return item
        }
        
        let controller = UIActivityViewController(
            activityItems: processedItems,
            applicationActivities: nil
        )
        
        // ✅ ИСПРАВЛЕНО: Настройки для файлового шаринга
        controller.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .postToVimeo,
            .postToWeibo,
            .postToFlickr,
            .postToTencentWeibo
        ]
        
        // ✅ ИСПРАВЛЕНО: Обработка completion
        controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            if let error = error {
                print("❌ Share error: \(error)")
            } else if completed {
                print("✅ Share completed successfully")
            } else {
                print("ℹ️ Share cancelled")
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Document Export Sheet (НОВОЕ: альтернатива для экспорта)
struct DocumentExportSheet: UIViewControllerRepresentable {
    let fileURL: URL
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [fileURL])
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .formSheet
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentExportSheet
        
        init(_ parent: DocumentExportSheet) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            print("✅ Document exported to: \(urls)")
            parent.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("ℹ️ Document export cancelled")
            parent.dismiss()
        }
    }
}

// MARK: - Export Options Enum (ИСПРАВЛЕНО)
enum ExportOption: String, CaseIterable {
    case expensesPDF = "expenses_pdf"
    case expensesCSV = "expenses_csv"
    case categoriesCSV = "categories_csv"
    case fullPDF = "full_pdf"
    case fullCSV = "full_csv"
    
    var title: String {
        switch self {
        case .expensesPDF:
            return "Expenses Report (PDF)"
        case .expensesCSV:
            return "Expenses Data (CSV)"
        case .categoriesCSV:
            return "Categories Data (CSV)"
        case .fullPDF:
            return "Complete Report (PDF)"
        case .fullCSV:
            return "Complete Data (CSV)"
        }
    }
    
    var subtitle: String {
        switch self {
        case .expensesPDF:
            return "Beautiful formatted report"
        case .expensesCSV:
            return "Expenses as spreadsheet"
        case .categoriesCSV:
            return "Categories as spreadsheet"
        case .fullPDF:
            return "Everything in beautiful format"
        case .fullCSV:
            return "Everything as spreadsheet"
        }
    }
    
    var icon: String {
        switch self {
        case .expensesPDF, .fullPDF:
            return "doc.richtext"
        case .expensesCSV, .categoriesCSV, .fullCSV:
            return "tablecells"
        }
    }
    
    var isPDF: Bool {
        switch self {
        case .expensesPDF, .fullPDF:
            return true
        case .expensesCSV, .categoriesCSV, .fullCSV:
            return false
        }
    }
    
    var recommendedTag: String? {
        switch self {
        case .expensesPDF:
            return "Recommended"
        case .fullPDF:
            return "Complete"
        default:
            return nil
        }
    }
    
    // ✅ НОВОЕ: Проверка доступности опции
    func isAvailable(expenses: [Expense], categories: [Category]) -> Bool {
        switch self {
        case .expensesPDF, .expensesCSV:
            return !expenses.isEmpty
        case .categoriesCSV:
            return !categories.isEmpty
        case .fullPDF, .fullCSV:
            return !expenses.isEmpty || !categories.isEmpty
        }
    }
}

// MARK: - Preview
#Preview("Export View") {
    DataExportView(appState: AppState.preview)
}

#Preview("Export View - Empty") {
    let emptyAppState = AppState.preview
    // Simulate empty state
    return DataExportView(appState: emptyAppState)
}

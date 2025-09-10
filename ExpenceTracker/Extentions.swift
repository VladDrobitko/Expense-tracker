//
//  Extensions.swift
//  ExpenseTracker
//
//  Created by Developer on 21/06/2025.
//

import SwiftUI

// MARK: - Color Extensions
extension Color {
    static let expensePurple = Color(red: 142/255, green: 108/255, blue: 239/255)
    static let expenseBlue = Color(red: 108/255, green: 166/255, blue: 239/255)
    static let expensePink = Color(red: 255/255, green: 105/255, blue: 180/255)
}

// MARK: - View Extensions
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Custom Modifiers
struct ExpenseCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func expenseCardStyle() -> some View {
        modifier(ExpenseCardStyle())
    }
}

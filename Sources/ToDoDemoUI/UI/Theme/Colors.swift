//
//  Colors.swift
//  ToDoDemoUI
//

import SwiftUI

extension Color {
    static let cardBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? .secondarySystemBackground : .white
    })
    static let onAccent = Color.white
    static let accentTint = Color(red: 0.78, green: 0.44, blue: 0.32)
}

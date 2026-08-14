//
//  CircularCheckbox.swift
//  ToDoDemoUI
//

import SwiftUI

private extension Color {
    static let accentTint = Color(red: 0.78, green: 0.44, blue: 0.32)
}

public struct CircularCheckbox: View {
    private let isChecked: Bool

    public init(isChecked: Bool) {
        self.isChecked = isChecked
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(isChecked ? Color.accentTint : Color.clear)
            Circle()
                .strokeBorder(isChecked ? Color.clear : Color.secondary, lineWidth: 2)
            if isChecked {
                Image(systemName: "checkmark")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
        }
        .frame(width: 24, height: 24)
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 16) {
        CircularCheckbox(isChecked: false)
        CircularCheckbox(isChecked: true)
    }
    .padding()
}
#endif

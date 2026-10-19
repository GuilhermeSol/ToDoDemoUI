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
    private let onTap: (() -> Void)?

    public init(isChecked: Bool, onTap: (() -> Void)? = nil) {
        self.isChecked = isChecked
        self.onTap = onTap
    }

    public var body: some View {
        if let onTap {
            Button(action: onTap) { circle }
                .buttonStyle(.plain)
        } else {
            circle
        }
    }

    private var circle: some View {
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

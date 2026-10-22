//
//  TextInputBar.swift
//  ToDoDemoUI
//

import SwiftUI

public struct TextInputBar: View {
    @Binding private var text: String
    private let placeholder: String
    private let onSubmit: () -> Void

    public init(text: Binding<String>, placeholder: String, onSubmit: @escaping () -> Void) {
        self._text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: 12) {
            TextField(placeholder, text: $text)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .onSubmit(onSubmit)

            Button(action: onSubmit) {
                Image(systemName: "plus")
                    .font(.headline)
                    .foregroundColor(Color.onAccent)
                    .frame(width: 44, height: 44)
                    .background(Color.accentTint)
                    .clipShape(Circle())
            }
        }
    }
}

#if DEBUG
private struct TextInputBarPreviewContainer: View {
    @State private var text = ""

    var body: some View {
        TextInputBar(text: $text, placeholder: "Add a to-do…", onSubmit: {})
            .padding()
    }
}

#Preview {
    TextInputBarPreviewContainer()
}

#Preview("Dark") {
    TextInputBarPreviewContainer()
        .background(Color(uiColor: .systemBackground))
        .environment(\.colorScheme, .dark)
}
#endif

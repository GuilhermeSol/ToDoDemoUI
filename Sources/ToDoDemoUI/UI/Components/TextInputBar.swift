//
//  TextInputBar.swift
//  ToDoDemoUI
//

import SwiftUI

private extension Color {
    static let accentTint = Color(red: 0.78, green: 0.44, blue: 0.32)
}

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
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .onSubmit(onSubmit)

            Button(action: onSubmit) {
                Image(systemName: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
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
#endif

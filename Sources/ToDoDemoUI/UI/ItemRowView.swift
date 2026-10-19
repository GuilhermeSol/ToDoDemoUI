//
//  ItemRowView.swift
//  ToDoDemoUI
//

import SwiftUI

public struct ItemRowView<Item: ItemDisplayable>: View {
    private let item: Item
    private let onToggle: () -> Void

    public init(item: Item, onToggle: @escaping () -> Void = {}) {
        self.item = item
        self.onToggle = onToggle
    }

    public var body: some View {
        Card {
            HStack(spacing: 12) {
                CircularCheckbox(isChecked: item.isCompleted, onTap: onToggle)
                Text(item.title)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                Spacer()
            }
        }
    }
}

#if DEBUG
import Foundation

private struct PreviewItem: ItemDisplayable {
    let id = UUID()
    var title: String
    var isCompleted: Bool

    func withCompletion(_ isCompleted: Bool) -> Self {
        var copy = self
        copy.isCompleted = isCompleted
        return copy
    }
}

#Preview {
    VStack {
        ItemRowView(item: PreviewItem(title: "Water the plants", isCompleted: false))
        ItemRowView(item: PreviewItem(title: "Reply to Sam", isCompleted: true))
    }
    .padding()
}
#endif

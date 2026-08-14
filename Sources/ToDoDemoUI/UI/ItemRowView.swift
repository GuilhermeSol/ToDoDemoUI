//
//  ItemRowView.swift
//  ToDoDemoUI
//

import SwiftUI

public struct ItemRowView<Item: ItemDisplayable>: View {
    private let item: Item

    public init(item: Item) {
        self.item = item
    }

    public var body: some View {
        Card {
            HStack(spacing: 12) {
                CircularCheckbox(isChecked: item.isCompleted)
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
}

#Preview {
    VStack {
        ItemRowView(item: PreviewItem(title: "Water the plants", isCompleted: false))
        ItemRowView(item: PreviewItem(title: "Reply to Sam", isCompleted: true))
    }
    .padding()
}
#endif

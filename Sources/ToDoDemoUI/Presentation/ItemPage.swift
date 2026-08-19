//
//  ItemPage.swift
//  ToDoDemoUI
//

public struct ItemPage<Item: ItemDisplayable>: Sendable {
    public let items: [Item]
    public let hasMore: Bool

    public init(items: [Item], hasMore: Bool) {
        self.items = items
        self.hasMore = hasMore
    }
}

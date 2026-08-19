//
//  ItemPaging.swift
//  ToDoDemoUI
//

/// A generic, item-agnostic paginated source of items for list-style presentation.
public protocol ItemPaging: Sendable {
    associatedtype Item: ItemDisplayable
    func fetchPage(offset: Int, limit: Int) async throws -> ItemPage<Item>
}

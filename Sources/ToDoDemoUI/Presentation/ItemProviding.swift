//
//  ItemProviding.swift
//  ToDoDemoUI
//

/// A generic, item-agnostic source of items for list-style presentation.
public protocol ItemProviding: Sendable {
    associatedtype Item: ItemDisplayable
    var items: [Item] { get }
}

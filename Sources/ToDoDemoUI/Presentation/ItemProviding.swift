//
//  ItemProviding.swift
//  ToDoDemoUI
//

/// A generic, item-agnostic source of items for list-style presentation.
public protocol ItemProviding {
    associatedtype Item
    var items: [Item] { get }
}

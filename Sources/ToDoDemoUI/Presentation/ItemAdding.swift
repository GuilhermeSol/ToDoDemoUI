//
//  ItemAdding.swift
//  ToDoDemoUI
//

public protocol ItemAdding: Sendable {
    associatedtype Item: ItemDisplayable
    func add(title: String) async throws -> Item
}

//
//  ItemDeleting.swift
//  ToDoDemoUI
//

public protocol ItemDeleting: Sendable {
    associatedtype Item: ItemDisplayable
    func delete(id: Item.ID) async throws
}

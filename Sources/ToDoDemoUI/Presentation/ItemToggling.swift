//
//  ItemToggling.swift
//  ToDoDemoUI
//

public protocol ItemToggling: Sendable {
    associatedtype Item: ItemDisplayable
    func toggle(id: Item.ID) async throws
}

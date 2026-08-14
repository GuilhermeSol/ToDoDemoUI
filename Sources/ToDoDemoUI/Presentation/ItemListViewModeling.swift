//
//  ItemListViewModeling.swift
//  ToDoDemoUI
//

import Combine

@MainActor
public protocol ItemListViewModeling: ObservableObject {
    associatedtype Item: ItemDisplayable
    var emptyMessage: String { get }
    var items: [Item] { get }
    var inputText: String { get set }
    var errorMessage: String? { get }
    func addTapped() async
    func dismissError()
}

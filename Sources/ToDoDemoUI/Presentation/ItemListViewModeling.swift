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
    var loadErrorMessage: String? { get }
    var deleteErrorMessage: String? { get }
    var showLoadMoreRetry: Bool { get }
    var hasLoaded: Bool { get }
    func addTapped() async
    func dismissError()
    func deleteTapped(_ item: Item) async
    func dismissDeleteError()
    func load() async
    func retryLoad() async
    func retryLoadMore() async
    func loadNextPageIfNeeded(after item: Item) async
}

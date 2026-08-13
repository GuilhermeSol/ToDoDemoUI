//
//  ItemListViewModel.swift
//  ToDoDemoUI
//

public final class ItemListViewModel<Provider: ItemProviding>: ItemListViewModeling {
    private let provider: Provider

    public init(provider: Provider) {
        self.provider = provider
    }

    public var emptyMessage: String {
        "no items"
    }
}

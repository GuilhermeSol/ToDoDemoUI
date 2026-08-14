//
//  ItemListViewModel.swift
//  ToDoDemoUI
//

import Combine
import Foundation

@MainActor
public final class ItemListViewModel<Provider: ItemProviding, Adder: ItemAdding>: ItemListViewModeling where Provider.Item == Adder.Item {
    private let provider: Provider
    private let adder: Adder

    @Published public var items: [Provider.Item]
    @Published public var inputText: String = ""
    @Published public var errorMessage: String?
    private var isSaving = false

    public init(provider: Provider, adder: Adder) {
        self.provider = provider
        self.adder = adder
        self.items = provider.items
    }

    public var emptyMessage: String {
        "no items"
    }

    public func addTapped() async {
        let trimmedTitle = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let newItem = try await adder.add(title: trimmedTitle)
            items.append(newItem)
            inputText = ""
        } catch {
            errorMessage = "Couldn't save your to-do. Please try again."
        }
    }

    public func dismissError() {
        errorMessage = nil
    }
}

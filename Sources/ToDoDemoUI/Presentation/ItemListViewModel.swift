//
//  ItemListViewModel.swift
//  ToDoDemoUI
//

import Combine
import Foundation

@MainActor
public final class ItemListViewModel<Pager: ItemPaging, Adder: ItemAdding, Deleter: ItemDeleting>: ItemListViewModeling where Pager.Item == Adder.Item, Pager.Item == Deleter.Item {
    private let pager: Pager
    private let adder: Adder
    private let deleter: Deleter

    @Published public var items: [Pager.Item] = []
    @Published public var inputText: String = ""
    @Published public var errorMessage: String?
    @Published public var loadErrorMessage: String?
    @Published public var deleteErrorMessage: String?
    @Published public var showLoadMoreRetry: Bool = false
    @Published public var hasLoaded: Bool = false
    private var isSaving = false
    private var isLoadingMore = false
    private var nextOffset = 0
    private var hasMore = false
    private var deletingItemIDs: Set<Pager.Item.ID> = []

    public init(pager: Pager, adder: Adder, deleter: Deleter) {
        self.pager = pager
        self.adder = adder
        self.deleter = deleter
    }

    public var emptyMessage: String {
        "no items"
    }

    public func load() async {
        do {
            let page = try await pager.fetchPage(offset: 0, limit: 30)
            items = page.items
            nextOffset = page.items.count
            hasMore = page.hasMore
            loadErrorMessage = nil
        } catch {
            loadErrorMessage = Strings.loadFailureMessage
        }
        hasLoaded = true
    }

    public func retryLoad() async {
        await load()
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

    public func deleteTapped(_ item: Pager.Item) async {
        guard !deletingItemIDs.contains(item.id) else { return }
        deletingItemIDs.insert(item.id)
        defer { deletingItemIDs.remove(item.id) }
        do {
            try await deleter.delete(id: item.id)
            items.removeAll { $0.id == item.id }
        } catch {
            deleteErrorMessage = Strings.deleteFailureMessage
        }
    }

    public func dismissDeleteError() {
        deleteErrorMessage = nil
    }

    public func retryLoadMore() async {
        await fetchNextPage()
    }

    public func loadNextPageIfNeeded(after item: Pager.Item) async {
        guard hasMore, item.id == items.last?.id else { return }
        await fetchNextPage()
    }

    private func fetchNextPage() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await pager.fetchPage(offset: nextOffset, limit: 30)
            items += page.items
            nextOffset += page.items.count
            hasMore = page.hasMore
            showLoadMoreRetry = false
        } catch {
            showLoadMoreRetry = true
        }
    }
}

private enum Strings {
    static let loadFailureMessage = "Couldn't load your to-dos. Please try again."
    static let deleteFailureMessage = "Couldn't delete your to-do. Please try again."
}

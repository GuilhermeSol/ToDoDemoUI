//
//  ItemListViewModel.swift
//  ToDoDemoUI
//

import Combine
import Foundation

@MainActor
public final class ItemListViewModel<Pager: ItemPaging, Adder: ItemAdding>: ItemListViewModeling where Pager.Item == Adder.Item {
    private let pager: Pager
    private let adder: Adder

    @Published public var items: [Pager.Item] = []
    @Published public var inputText: String = ""
    @Published public var errorMessage: String?
    @Published public var loadErrorMessage: String?
    @Published public var showLoadMoreRetry: Bool = false
    @Published public var hasLoaded: Bool = false
    private var isSaving = false
    private var isLoadingMore = false
    private var nextOffset = 0
    private var hasMore = false

    public init(pager: Pager, adder: Adder) {
        self.pager = pager
        self.adder = adder
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
}

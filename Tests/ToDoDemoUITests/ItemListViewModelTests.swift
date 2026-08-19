//
//  ItemListViewModelTests.swift
//  ToDoDemoUITests
//

import Foundation
import Testing
@testable import ToDoDemoUI

struct FakeItem: ItemDisplayable {
    let id = UUID()
    var title: String = ""
    var isCompleted: Bool = false
}

struct StubItemPager<Item: ItemDisplayable>: ItemPaging {
    let result: Result<ItemPage<Item>, TestError>
    func fetchPage(offset: Int, limit: Int) async throws -> ItemPage<Item> {
        try result.get()
    }
}

struct TestError: Error {}

/// Returns queued results in call order; once exhausted, repeats the last result. Tracks call count for pagination assertions.
actor SequencedItemPager<Item: ItemDisplayable>: ItemPaging {
    private let results: [Result<ItemPage<Item>, TestError>]
    private(set) var callCount = 0

    init(results: [Result<ItemPage<Item>, TestError>]) {
        self.results = results
    }

    func fetchPage(offset: Int, limit: Int) async throws -> ItemPage<Item> {
        callCount += 1
        let index = min(callCount - 1, results.count - 1)
        return try results[index].get()
    }
}

actor CallSpy {
    private(set) var callCount = 0
    private(set) var receivedTitle: String?
    func record(title: String? = nil) {
        callCount += 1
        receivedTitle = title
    }
}

struct StubItemAdder<Item: ItemDisplayable>: ItemAdding {
    let result: Result<Item, TestError>
    var spy: CallSpy?

    func add(title: String) async throws -> Item {
        await spy?.record(title: title)
        return try result.get()
    }
}

actor Signal {
    private var continuation: CheckedContinuation<Void, Never>?
    private var fired = false

    func wait() async {
        if fired { return }
        await withCheckedContinuation { continuation = $0 }
    }

    func fire() {
        fired = true
        continuation?.resume()
        continuation = nil
    }
}

struct GatedItemAdder<Item: ItemDisplayable>: ItemAdding {
    let entered: Signal
    let release: Signal
    let result: Item
    let spy: CallSpy?

    func add(title: String) async throws -> Item {
        await spy?.record(title: title)
        await entered.fire()
        await release.wait()
        return result
    }
}

/// Unlike Signal, supports multiple concurrent waiters — needed when two in-flight calls gate on the same release.
actor Gate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }
}

/// First call (page 1) resolves immediately; every call after that gates on entered/release, mirroring GatedItemAdder for pagination.
actor GatedItemPager<Item: ItemDisplayable>: ItemPaging {
    private let firstPageResult: ItemPage<Item>
    private let gatedPageResult: ItemPage<Item>
    private let entered: Signal
    private let release: Gate
    private(set) var callCount = 0

    init(firstPageResult: ItemPage<Item>, gatedPageResult: ItemPage<Item>, entered: Signal, release: Gate) {
        self.firstPageResult = firstPageResult
        self.gatedPageResult = gatedPageResult
        self.entered = entered
        self.release = release
    }

    func fetchPage(offset: Int, limit: Int) async throws -> ItemPage<Item> {
        callCount += 1
        guard callCount > 1 else { return firstPageResult }
        await entered.fire()
        await release.wait()
        return gatedPageResult
    }
}

@MainActor
struct ItemListViewModelTests {
    @Test("Given a provider with no items, when reading emptyMessage, then it reads 'no items'")
    func test_emptyMessage_whenProviderReturnsNoItems() {
        let viewModel = ItemListViewModel(pager: StubItemPager<FakeItem>(result: .success(ItemPage(items: [], hasMore: false))), adder: StubItemAdder<FakeItem>(result: .failure(TestError())))

        #expect(viewModel.emptyMessage == "no items")
    }

    @Test("Given a provider with items, when reading emptyMessage, then it reads 'no items'")
    func test_emptyMessage_whenProviderReturnsItems() {
        let viewModel = ItemListViewModel(pager: StubItemPager<FakeItem>(result: .success(ItemPage(items: [FakeItem(), FakeItem()], hasMore: false))), adder: StubItemAdder<FakeItem>(result: .failure(TestError())))

        #expect(viewModel.emptyMessage == "no items")
    }

    @Test("Given non-empty text in the input bar, when addTapped is called and the adder throws, then errorMessage is set, items is unchanged, and inputText is preserved")
    func testAddTapped_whenSaveFails_setsErrorAndPreservesInput() async {
        let viewModel = ItemListViewModel(pager: StubItemPager<FakeItem>(result: .success(ItemPage(items: [], hasMore: false))), adder: StubItemAdder<FakeItem>(result: .failure(TestError())))
        viewModel.inputText = "Buy oat milk"

        await viewModel.addTapped()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.items.isEmpty)
        #expect(viewModel.inputText == "Buy oat milk")
    }

    @Test("Given a save-failure error is currently shown, when dismissError is called, then errorMessage is cleared while inputText is preserved")
    func testDismissError_clearsErrorWhileKeepingInputText() async {
        let viewModel = ItemListViewModel(pager: StubItemPager<FakeItem>(result: .success(ItemPage(items: [], hasMore: false))), adder: StubItemAdder<FakeItem>(result: .failure(TestError())))
        viewModel.inputText = "Buy oat milk"
        await viewModel.addTapped()

        viewModel.dismissError()

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.inputText == "Buy oat milk")
    }

    @Test("Given the input bar is empty, when addTapped is called, then the adder is never invoked and items stays unchanged")
    func testAddTapped_withEmptyInput_doesNothing() async {
        let spy = CallSpy()
        let viewModel = ItemListViewModel(pager: StubItemPager<FakeItem>(result: .success(ItemPage(items: [], hasMore: false))), adder: StubItemAdder<FakeItem>(result: .failure(TestError()), spy: spy))
        viewModel.inputText = ""

        await viewModel.addTapped()

        #expect(await spy.callCount == 0)
        #expect(viewModel.items.isEmpty)
    }

    @Test("Given the input bar contains only whitespace, when addTapped is called, then the adder is never invoked and inputText is not cleared")
    func testAddTapped_withWhitespaceOnlyInput_doesNothing() async {
        let spy = CallSpy()
        let viewModel = ItemListViewModel(pager: StubItemPager<FakeItem>(result: .success(ItemPage(items: [], hasMore: false))), adder: StubItemAdder<FakeItem>(result: .failure(TestError()), spy: spy))
        viewModel.inputText = "   "

        await viewModel.addTapped()

        #expect(await spy.callCount == 0)
        #expect(viewModel.inputText == "   ")
    }

    @Test("Given text with leading/trailing whitespace, when addTapped is called, then the adder receives the trimmed title")
    func testAddTapped_trimsWhitespaceBeforeSaving() async {
        let spy = CallSpy()
        let viewModel = ItemListViewModel(pager: StubItemPager<FakeItem>(result: .success(ItemPage(items: [], hasMore: false))), adder: StubItemAdder<FakeItem>(result: .success(FakeItem(title: "Buy oat milk")), spy: spy))
        viewModel.inputText = "  Buy oat milk  "

        await viewModel.addTapped()

        #expect(await spy.receivedTitle == "Buy oat milk")
    }

    @Test("Given a save is already in flight, when addTapped is called again, then the adder is not invoked a second time")
    func testAddTapped_whileSaveInFlight_ignoresSecondTap() async {
        let entered = Signal()
        let release = Signal()
        let spy = CallSpy()
        let viewModel = ItemListViewModel(
            pager: StubItemPager<FakeItem>(result: .success(ItemPage(items: [], hasMore: false))),
            adder: GatedItemAdder(entered: entered, release: release, result: FakeItem(title: "Buy oat milk"), spy: spy)
        )
        viewModel.inputText = "Buy oat milk"

        let firstTask = Task { await viewModel.addTapped() }
        await entered.wait()
        let secondTask = Task { await viewModel.addTapped() }

        await release.fire()
        await firstTask.value
        await secondTask.value

        #expect(await spy.callCount == 1)
    }

    @Test("Given non-empty text in the input bar, when addTapped is called and the adder succeeds, then the returned item is appended to items and inputText is cleared")
    func testAddTapped_withValidText_appendsItemAndClearsInput() async {
        let newItem = FakeItem(title: "Buy oat milk")
        let viewModel = ItemListViewModel(pager: StubItemPager<FakeItem>(result: .success(ItemPage(items: [], hasMore: false))), adder: StubItemAdder<FakeItem>(result: .success(newItem)))
        viewModel.inputText = "Buy oat milk"

        await viewModel.addTapped()

        #expect(viewModel.items.map(\.title) == ["Buy oat milk"])
        #expect(viewModel.inputText == "")
    }

    @Test("Given the provider seeds the list with an existing item, when addTapped succeeds, then the new item appears after the existing item")
    func testAddTapped_appendsNewItemAfterExistingItems() async {
        let existingItem = FakeItem(title: "Reply to Sam")
        let newItem = FakeItem(title: "Buy oat milk")
        let viewModel = ItemListViewModel(pager: StubItemPager<FakeItem>(result: .success(ItemPage(items: [existingItem], hasMore: false))), adder: StubItemAdder<FakeItem>(result: .success(newItem)))
        await viewModel.load()
        viewModel.inputText = "Buy oat milk"

        await viewModel.addTapped()

        #expect(viewModel.items.map(\.title) == ["Reply to Sam", "Buy oat milk"])
    }

    @Test("Given zero saved to-dos exist, when the screen loads, then the existing empty-state message is shown with no error or retry control")
    func testLoad_zeroItems_showsEmptyStateNoError() async {
        let viewModel = ItemListViewModel(pager: StubItemPager<FakeItem>(result: .success(ItemPage(items: [], hasMore: false))), adder: StubItemAdder<FakeItem>(result: .failure(TestError())))

        await viewModel.load()

        #expect(viewModel.items.isEmpty)
        #expect(viewModel.loadErrorMessage == nil)
    }

    @Test("Given a freshly constructed view model, when load completes successfully, then hasLoaded transitions from false to true")
    func testHasLoaded_beforeAndAfterLoad() async {
        let viewModel = ItemListViewModel(pager: StubItemPager<FakeItem>(result: .success(ItemPage(items: [], hasMore: false))), adder: StubItemAdder<FakeItem>(result: .failure(TestError())))

        #expect(viewModel.hasLoaded == false)

        await viewModel.load()

        #expect(viewModel.hasLoaded == true)
    }

    @Test("Given the initial fetch fails, when the screen loads, then a full-screen error message is shown instead of the list")
    func testLoad_whenFetchFails_setsLoadErrorMessage() async {
        let viewModel = ItemListViewModel(pager: StubItemPager<FakeItem>(result: .failure(TestError())), adder: StubItemAdder<FakeItem>(result: .failure(TestError())))

        await viewModel.load()

        #expect(viewModel.loadErrorMessage != nil)
        #expect(viewModel.items.isEmpty)
    }

    @Test("Given the full-screen error state is shown after a failed initial load, when retryLoad is called and the fetch succeeds, then the error is cleared and the first page of items is shown")
    func testRetryLoad_whenFetchSucceeds_clearsErrorAndShowsItems() async {
        let existingItem = FakeItem(title: "Reply to Sam")
        let newItem = FakeItem(title: "Buy oat milk")
        let pager = SequencedItemPager<FakeItem>(results: [.failure(TestError()), .success(ItemPage(items: [existingItem, newItem], hasMore: false))])
        let viewModel = ItemListViewModel(pager: pager, adder: StubItemAdder<FakeItem>(result: .failure(TestError())))
        await viewModel.load()

        await viewModel.retryLoad()

        #expect(viewModel.loadErrorMessage == nil)
        #expect(viewModel.items.map(\.title) == ["Reply to Sam", "Buy oat milk"])
    }

    @Test("Given the full-screen error state is shown, when the user taps Retry and the fetch fails again, then the full-screen error state remains shown")
    func testRetryLoad_whenFetchFailsAgain_keepsLoadErrorMessage() async {
        let pager = SequencedItemPager<FakeItem>(results: [.failure(TestError())])
        let viewModel = ItemListViewModel(pager: pager, adder: StubItemAdder<FakeItem>(result: .failure(TestError())))
        await viewModel.load()

        await viewModel.retryLoad()

        #expect(viewModel.loadErrorMessage != nil)
        #expect(viewModel.items.isEmpty)
    }

    @Test("Given page 1 is displayed and the page-2 load-more fetch fails, when loadNextPageIfNeeded is called, then the already-displayed items remain visible and showLoadMoreRetry is true")
    func testLoadNextPageIfNeeded_whenFetchFails_keepsItemsAndShowsRetryRow() async {
        let page1Items = (0..<30).map { FakeItem(title: "Item \($0)") }
        let pager = SequencedItemPager<FakeItem>(results: [.success(ItemPage(items: page1Items, hasMore: true)), .failure(TestError())])
        let viewModel = ItemListViewModel(pager: pager, adder: StubItemAdder<FakeItem>(result: .failure(TestError())))
        await viewModel.load()

        await viewModel.loadNextPageIfNeeded(after: viewModel.items.last!)

        #expect(viewModel.items.count == 30)
        #expect(viewModel.showLoadMoreRetry == true)
    }

    @Test("Given the inline retry row is shown after a failed load-more fetch, when retryLoadMore is called and the fetch succeeds, then the next page is appended and the retry row is hidden")
    func testRetryLoadMore_whenFetchSucceeds_appendsPageAndHidesRetryRow() async {
        let page1Items = (0..<30).map { FakeItem(title: "Item \($0)") }
        let page2Items = (0..<15).map { FakeItem(title: "Item 30-\($0)") }
        let pager = SequencedItemPager<FakeItem>(results: [
            .success(ItemPage(items: page1Items, hasMore: true)),
            .failure(TestError()),
            .success(ItemPage(items: page2Items, hasMore: false))
        ])
        let viewModel = ItemListViewModel(pager: pager, adder: StubItemAdder<FakeItem>(result: .failure(TestError())))
        await viewModel.load()
        await viewModel.loadNextPageIfNeeded(after: viewModel.items.last!)

        await viewModel.retryLoadMore()

        #expect(viewModel.items.count == 45)
        #expect(viewModel.showLoadMoreRetry == false)
    }

    @Test("Given the inline retry row is shown after a failed load-more fetch, when retryLoadMore is called and the fetch fails again, then the retry row remains shown and no items are lost")
    func testRetryLoadMore_whenFetchFailsAgain_keepsRetryRowVisible() async {
        let page1Items = (0..<30).map { FakeItem(title: "Item \($0)") }
        let pager = SequencedItemPager<FakeItem>(results: [
            .success(ItemPage(items: page1Items, hasMore: true)),
            .failure(TestError())
        ])
        let viewModel = ItemListViewModel(pager: pager, adder: StubItemAdder<FakeItem>(result: .failure(TestError())))
        await viewModel.load()
        await viewModel.loadNextPageIfNeeded(after: viewModel.items.last!)

        await viewModel.retryLoadMore()

        #expect(viewModel.showLoadMoreRetry == true)
        #expect(viewModel.items.count == 30)
    }

    @Test("Given 45 saved to-dos exist, when the screen loads, then the first 30 items are displayed in order")
    func testLoad_returnsFirstPageOfThirtyItems() async {
        let items = (1...30).map { FakeItem(title: "Item \($0)") }
        let pager = SequencedItemPager<FakeItem>(results: [.success(ItemPage(items: items, hasMore: true))])
        let viewModel = ItemListViewModel(pager: pager, adder: StubItemAdder<FakeItem>(result: .failure(TestError())))

        await viewModel.load()

        #expect(viewModel.items.count == 30)
        #expect(viewModel.items.map(\.title) == items.map(\.title))
    }

    @Test("Given exactly 30 saved to-dos exist, when the screen loads, then all 30 items are displayed with hasMore false, and the last row appearing does not trigger another fetch")
    func testLoad_exactlyThirtyItems_noFurtherFetchTriggered() async {
        let items = (0..<30).map { FakeItem(title: "Item \($0)") }
        let pager = SequencedItemPager<FakeItem>(results: [.success(ItemPage(items: items, hasMore: false))])
        let viewModel = ItemListViewModel(pager: pager, adder: StubItemAdder<FakeItem>(result: .failure(TestError())))

        await viewModel.load()
        await viewModel.loadNextPageIfNeeded(after: viewModel.items.last!)

        #expect(viewModel.items.count == 30)
        #expect(await pager.callCount == 1)
    }

    @Test("Given 10 saved to-dos exist, when the screen loads, then all 10 items are displayed and no load-more fetch is triggered")
    func testLoad_fewerThanOnePage_displaysAllItemsWithNoMoreToLoad() async {
        let items = (0..<10).map { FakeItem(title: "Item \($0)") }
        let pager = SequencedItemPager<FakeItem>(results: [.success(ItemPage(items: items, hasMore: false))])
        let viewModel = ItemListViewModel(pager: pager, adder: StubItemAdder<FakeItem>(result: .failure(TestError())))

        await viewModel.load()
        await viewModel.loadNextPageIfNeeded(after: viewModel.items.last!)

        #expect(viewModel.items.count == 10)
        #expect(await pager.callCount == 1)
    }

    @Test("Given exactly 60 saved to-dos exist, when the screen loads and the last row of page 1 appears, then page 2 loads, hasMore becomes false, and no third fetch is triggered even when loadNextPageIfNeeded is called again on the new last item")
    func testLoadNextPageIfNeeded_twoFullPages_stopsAfterSecondPage() async {
        let page1Items = (0..<30).map { FakeItem(title: "Item \($0)") }
        let page2Items = (30..<60).map { FakeItem(title: "Item \($0)") }
        let pager = SequencedItemPager<FakeItem>(results: [
            .success(ItemPage(items: page1Items, hasMore: true)),
            .success(ItemPage(items: page2Items, hasMore: false))
        ])
        let viewModel = ItemListViewModel(pager: pager, adder: StubItemAdder<FakeItem>(result: .failure(TestError())))

        await viewModel.load()
        await viewModel.loadNextPageIfNeeded(after: viewModel.items.last!)
        await viewModel.loadNextPageIfNeeded(after: viewModel.items.last!)

        #expect(viewModel.items.count == 60)
        #expect(await pager.callCount == 2)
    }

    @Test("Given 45 saved to-dos exist and page 1 is displayed, when the last visible row appears on screen, then the remaining 15 items are fetched and appended, for 45 total displayed items")
    func testLoadNextPageIfNeeded_afterLastRow_appendsNextPage() async {
        let page1Items = (0..<30).map { FakeItem(title: "Item \($0)") }
        let page2Items = (0..<15).map { FakeItem(title: "Item 30-\($0)") }
        let pager = SequencedItemPager<FakeItem>(results: [
            .success(ItemPage(items: page1Items, hasMore: true)),
            .success(ItemPage(items: page2Items, hasMore: false))
        ])
        let viewModel = ItemListViewModel(pager: pager, adder: StubItemAdder<FakeItem>(result: .failure(TestError())))
        await viewModel.load()

        await viewModel.loadNextPageIfNeeded(after: viewModel.items.last!)

        #expect(viewModel.items.count == 45)
    }

    @Test("Given a load-more fetch is already in flight, when the last row appears again before that fetch completes, then a duplicate fetch for the same page is not started")
    func testLoadNextPageIfNeeded_whileFetchInFlight_ignoresDuplicateTrigger() async {
        let page1Items = (0..<30).map { FakeItem(title: "Item \($0)") }
        let page2Items = (0..<15).map { FakeItem(title: "Item 30-\($0)") }
        let entered = Signal()
        let release = Gate()
        let pager = GatedItemPager<FakeItem>(
            firstPageResult: ItemPage(items: page1Items, hasMore: true),
            gatedPageResult: ItemPage(items: page2Items, hasMore: false),
            entered: entered,
            release: release
        )
        let viewModel = ItemListViewModel(pager: pager, adder: StubItemAdder<FakeItem>(result: .failure(TestError())))
        await viewModel.load()
        let lastItem = viewModel.items.last!

        let firstTask = Task { await viewModel.loadNextPageIfNeeded(after: lastItem) }
        await entered.wait()
        let secondTask = Task { await viewModel.loadNextPageIfNeeded(after: lastItem) }

        await release.open()
        await firstTask.value
        await secondTask.value

        #expect(await pager.callCount == 2)
    }

    @Test("Given a load-more fetch is in flight, when the user adds a new to-do via the input bar, then the new item is appended independently of the pagination fetch")
    func testAddTapped_whileLoadMoreInFlight_appendsIndependently() async {
        let page1Items = (0..<30).map { FakeItem(title: "Item \($0)") }
        let page2Items = (0..<15).map { FakeItem(title: "Item 30-\($0)") }
        let newItem = FakeItem(title: "Buy oat milk")
        let entered = Signal()
        let release = Gate()
        let pager = GatedItemPager<FakeItem>(
            firstPageResult: ItemPage(items: page1Items, hasMore: true),
            gatedPageResult: ItemPage(items: page2Items, hasMore: false),
            entered: entered,
            release: release
        )
        let viewModel = ItemListViewModel(pager: pager, adder: StubItemAdder<FakeItem>(result: .success(newItem)))
        await viewModel.load()
        let lastItem = viewModel.items.last!

        let loadMoreTask = Task { await viewModel.loadNextPageIfNeeded(after: lastItem) }
        await entered.wait()
        viewModel.inputText = "Buy oat milk"
        await viewModel.addTapped()

        #expect(viewModel.items.map(\.title).last == "Buy oat milk")
        #expect(viewModel.inputText == "")

        await release.open()
        await loadMoreTask.value
    }
}

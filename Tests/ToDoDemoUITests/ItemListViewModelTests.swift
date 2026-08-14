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

struct StubItemProvider<Item: ItemDisplayable>: ItemProviding {
    let items: [Item]
}

struct TestError: Error {}

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

@MainActor
struct ItemListViewModelTests {
    @Test("Given a provider with no items, when reading emptyMessage, then it reads 'no items'")
    func test_emptyMessage_whenProviderReturnsNoItems() {
        let viewModel = ItemListViewModel(provider: StubItemProvider<FakeItem>(items: []), adder: StubItemAdder<FakeItem>(result: .failure(TestError())))

        #expect(viewModel.emptyMessage == "no items")
    }

    @Test("Given a provider with items, when reading emptyMessage, then it reads 'no items'")
    func test_emptyMessage_whenProviderReturnsItems() {
        let viewModel = ItemListViewModel(provider: StubItemProvider<FakeItem>(items: [FakeItem(), FakeItem()]), adder: StubItemAdder<FakeItem>(result: .failure(TestError())))

        #expect(viewModel.emptyMessage == "no items")
    }

    @Test("Given non-empty text in the input bar, when addTapped is called and the adder throws, then errorMessage is set, items is unchanged, and inputText is preserved")
    func testAddTapped_whenSaveFails_setsErrorAndPreservesInput() async {
        let viewModel = ItemListViewModel(provider: StubItemProvider<FakeItem>(items: []), adder: StubItemAdder<FakeItem>(result: .failure(TestError())))
        viewModel.inputText = "Buy oat milk"

        await viewModel.addTapped()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.items.isEmpty)
        #expect(viewModel.inputText == "Buy oat milk")
    }

    @Test("Given a save-failure error is currently shown, when dismissError is called, then errorMessage is cleared while inputText is preserved")
    func testDismissError_clearsErrorWhileKeepingInputText() async {
        let viewModel = ItemListViewModel(provider: StubItemProvider<FakeItem>(items: []), adder: StubItemAdder<FakeItem>(result: .failure(TestError())))
        viewModel.inputText = "Buy oat milk"
        await viewModel.addTapped()

        viewModel.dismissError()

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.inputText == "Buy oat milk")
    }

    @Test("Given the input bar is empty, when addTapped is called, then the adder is never invoked and items stays unchanged")
    func testAddTapped_withEmptyInput_doesNothing() async {
        let spy = CallSpy()
        let viewModel = ItemListViewModel(provider: StubItemProvider<FakeItem>(items: []), adder: StubItemAdder<FakeItem>(result: .failure(TestError()), spy: spy))
        viewModel.inputText = ""

        await viewModel.addTapped()

        #expect(await spy.callCount == 0)
        #expect(viewModel.items.isEmpty)
    }

    @Test("Given the input bar contains only whitespace, when addTapped is called, then the adder is never invoked and inputText is not cleared")
    func testAddTapped_withWhitespaceOnlyInput_doesNothing() async {
        let spy = CallSpy()
        let viewModel = ItemListViewModel(provider: StubItemProvider<FakeItem>(items: []), adder: StubItemAdder<FakeItem>(result: .failure(TestError()), spy: spy))
        viewModel.inputText = "   "

        await viewModel.addTapped()

        #expect(await spy.callCount == 0)
        #expect(viewModel.inputText == "   ")
    }

    @Test("Given text with leading/trailing whitespace, when addTapped is called, then the adder receives the trimmed title")
    func testAddTapped_trimsWhitespaceBeforeSaving() async {
        let spy = CallSpy()
        let viewModel = ItemListViewModel(provider: StubItemProvider<FakeItem>(items: []), adder: StubItemAdder<FakeItem>(result: .success(FakeItem(title: "Buy oat milk")), spy: spy))
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
            provider: StubItemProvider<FakeItem>(items: []),
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
        let viewModel = ItemListViewModel(provider: StubItemProvider<FakeItem>(items: []), adder: StubItemAdder<FakeItem>(result: .success(newItem)))
        viewModel.inputText = "Buy oat milk"

        await viewModel.addTapped()

        #expect(viewModel.items.map(\.title) == ["Buy oat milk"])
        #expect(viewModel.inputText == "")
    }

    @Test("Given the provider seeds the list with an existing item, when addTapped succeeds, then the new item appears after the existing item")
    func testAddTapped_appendsNewItemAfterExistingItems() async {
        let existingItem = FakeItem(title: "Reply to Sam")
        let newItem = FakeItem(title: "Buy oat milk")
        let viewModel = ItemListViewModel(provider: StubItemProvider<FakeItem>(items: [existingItem]), adder: StubItemAdder<FakeItem>(result: .success(newItem)))
        viewModel.inputText = "Buy oat milk"

        await viewModel.addTapped()

        #expect(viewModel.items.map(\.title) == ["Reply to Sam", "Buy oat milk"])
    }
}

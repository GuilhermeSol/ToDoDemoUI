//
//  ItemListViewModelTests.swift
//  ToDoDemoUITests
//

import Testing
@testable import ToDoDemoUI

struct FakeItem {}

struct StubItemProvider<Item>: ItemProviding {
    let items: [Item]
}

struct ItemListViewModelTests {
    @Test("Given a provider with no items, when reading emptyMessage, then it reads 'no items'")
    func test_emptyMessage_whenProviderReturnsNoItems() {
        let viewModel = ItemListViewModel(provider: StubItemProvider<FakeItem>(items: []))

        #expect(viewModel.emptyMessage == "no items")
    }

    @Test("Given a provider with items, when reading emptyMessage, then it reads 'no items'")
    func test_emptyMessage_whenProviderReturnsItems() {
        let viewModel = ItemListViewModel(provider: StubItemProvider<FakeItem>(items: [FakeItem(), FakeItem()]))

        #expect(viewModel.emptyMessage == "no items")
    }
}

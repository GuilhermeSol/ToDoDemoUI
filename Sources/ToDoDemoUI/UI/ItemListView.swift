//
//  ItemListView.swift
//  ToDoDemoUI
//

import SwiftUI

public struct ItemListView<ViewModel: ItemListViewModeling>: View {
    @ObservedObject private var viewModel: ViewModel

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let loadErrorMessage = viewModel.loadErrorMessage {
                Spacer()
                VStack(spacing: 12) {
                    Text(loadErrorMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button(Strings.retry) {
                        Task { await viewModel.retryLoad() }
                    }
                }
                .padding()
                Spacer()
            } else if viewModel.hasLoaded && viewModel.items.isEmpty {
                Spacer()
                Text(viewModel.emptyMessage)
                    .foregroundColor(.secondary)
                Spacer()
            } else if viewModel.items.isEmpty {
                EmptyView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.items) { item in
                            ItemRowView(item: item)
                                .onAppear {
                                    Task { await viewModel.loadNextPageIfNeeded(after: item) }
                                }
                        }
                        if viewModel.showLoadMoreRetry {
                            Button(Strings.retry) {
                                Task { await viewModel.retryLoadMore() }
                            }
                        }
                    }
                    .padding()
                }
            }

            TextInputBar(text: $viewModel.inputText, placeholder: "Add a to-do…") {
                Task { await viewModel.addTapped() }
            }
            .padding()
        }
        .task {
            await viewModel.load()
        }
        .alert(
            "Couldn't save your to-do",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { isPresented in if !isPresented { viewModel.dismissError() } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private enum Strings {
    static let retry = "Retry"
}

#if DEBUG
import Foundation

private struct PreviewItem: ItemDisplayable {
    let id = UUID()
    var title: String = ""
    var isCompleted: Bool = false
}

private struct PreviewItemPager: ItemPaging {
    let items: [PreviewItem]
    func fetchPage(offset: Int, limit: Int) async throws -> ItemPage<PreviewItem> {
        ItemPage(items: items, hasMore: false)
    }
}

private struct PreviewItemAdder: ItemAdding {
    func add(title: String) async throws -> PreviewItem {
        PreviewItem(title: title)
    }
}

private struct PreviewFailingPager: ItemPaging {
    private struct PreviewLoadError: Error {}
    func fetchPage(offset: Int, limit: Int) async throws -> ItemPage<PreviewItem> {
        throw PreviewLoadError()
    }
}

#Preview("Empty") {
    ItemListView(viewModel: ItemListViewModel(pager: PreviewItemPager(items: []), adder: PreviewItemAdder()))
}

#Preview("Populated") {
    ItemListView(viewModel: ItemListViewModel(
        pager: PreviewItemPager(items: [
            PreviewItem(title: "Water the plants", isCompleted: false),
            PreviewItem(title: "Reply to Sam", isCompleted: true),
            PreviewItem(title: "Buy oat milk", isCompleted: false),
        ]),
        adder: PreviewItemAdder()
    ))
}

#Preview("Load Error") {
    ItemListView(viewModel: ItemListViewModel(pager: PreviewFailingPager(), adder: PreviewItemAdder()))
}

#Preview("Load More Retry") {
    let viewModel = ItemListViewModel(
        pager: PreviewItemPager(items: [
            PreviewItem(title: "Water the plants", isCompleted: false),
            PreviewItem(title: "Reply to Sam", isCompleted: true),
        ]),
        adder: PreviewItemAdder()
    )
    viewModel.showLoadMoreRetry = true
    return ItemListView(viewModel: viewModel)
}
#endif

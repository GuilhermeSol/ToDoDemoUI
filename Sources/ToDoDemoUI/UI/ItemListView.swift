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
            if viewModel.items.isEmpty {
                Spacer()
                Text(viewModel.emptyMessage)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.items) { item in
                            ItemRowView(item: item)
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

#if DEBUG
import Foundation

private struct PreviewItem: ItemDisplayable {
    let id = UUID()
    var title: String = ""
    var isCompleted: Bool = false
}

private struct PreviewItemProvider: ItemProviding {
    let items: [PreviewItem]
}

private struct PreviewItemAdder: ItemAdding {
    func add(title: String) async throws -> PreviewItem {
        PreviewItem(title: title)
    }
}

#Preview("Empty") {
    ItemListView(viewModel: ItemListViewModel(provider: PreviewItemProvider(items: []), adder: PreviewItemAdder()))
}

#Preview("Populated") {
    ItemListView(viewModel: ItemListViewModel(
        provider: PreviewItemProvider(items: [
            PreviewItem(title: "Water the plants", isCompleted: false),
            PreviewItem(title: "Reply to Sam", isCompleted: true),
            PreviewItem(title: "Buy oat milk", isCompleted: false),
        ]),
        adder: PreviewItemAdder()
    ))
}
#endif
